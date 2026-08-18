/**
 * MOMO AI — Stable Diffusion JNI Bridge
 * Links against stable-diffusion.cpp (leejet/stable-diffusion.cpp) static lib.
 * Exposes JNI symbols callable from ImageGenBridge.kt.
 */

#include <jni.h>
#include <string>
#include <cstring>
#include <cstdlib>
#include <android/log.h>

// Include the correct header path
#include "stable-diffusion.h"

// stb_image_write — header-only, include directly
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define LOG_TAG "MomoSD"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#include <mutex>

// Global SD context — cached across calls so model isn't reloaded every generation
static std::mutex g_ctx_mutex;
static sd_ctx_t* g_sd_ctx = nullptr;
static std::string g_loaded_model_path;

static void freeContextLocked() {
    if (g_sd_ctx != nullptr) {
        free_sd_ctx(g_sd_ctx);
        g_sd_ctx = nullptr;
        g_loaded_model_path = "";
        LOGI("SD context freed");
    }
}

static void freeContext() {
    std::lock_guard<std::mutex> lock(g_ctx_mutex);
    freeContextLocked();
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_momoai_babymomo_bridge_ImageGenBridge_sdGenerate(
        JNIEnv* env,
        jobject /* this */,
        jstring modelPath,
        jstring prompt,
        jstring negativePrompt,
        jint width,
        jint height,
        jint steps,
        jfloat cfgScale,
        jlong seed,
        jstring outputPath) {

    if (modelPath == nullptr || prompt == nullptr || negativePrompt == nullptr || outputPath == nullptr) {
        LOGE("sdGenerate: null JNI string arguments passed");
        return JNI_FALSE;
    }

    const char* model_path_c  = env->GetStringUTFChars(modelPath, nullptr);
    const char* prompt_c      = env->GetStringUTFChars(prompt, nullptr);
    const char* neg_c         = env->GetStringUTFChars(negativePrompt, nullptr);
    const char* out_path_c    = env->GetStringUTFChars(outputPath, nullptr);

    if (model_path_c == nullptr || prompt_c == nullptr || neg_c == nullptr || out_path_c == nullptr) {
        LOGE("sdGenerate: failed to get UTF chars from Java strings");
        if (model_path_c) env->ReleaseStringUTFChars(modelPath, model_path_c);
        if (prompt_c) env->ReleaseStringUTFChars(prompt, prompt_c);
        if (neg_c) env->ReleaseStringUTFChars(negativePrompt, neg_c);
        if (out_path_c) env->ReleaseStringUTFChars(outputPath, out_path_c);
        return JNI_FALSE;
    }

    LOGI("sdGenerate: model=%s w=%d h=%d steps=%d", model_path_c, width, height, steps);

    jboolean result = JNI_FALSE;
    std::string model_str(model_path_c);

    {
        std::lock_guard<std::mutex> lock(g_ctx_mutex);

        // Load or reload the model context if path changed
        if (g_sd_ctx == nullptr || g_loaded_model_path != model_str) {
            freeContextLocked();
            LOGI("Loading model: %s", model_path_c);

            sd_ctx_params_t params;
            sd_ctx_params_init(&params);

            params.model_path             = model_path_c;
            params.clip_l_path            = "";
            params.clip_g_path            = "";
            params.t5xxl_path             = "";
            params.diffusion_model_path   = "";
            params.vae_path               = "";
            params.taesd_path             = "";
            params.control_net_path       = "";
            params.embeddings             = nullptr;
            params.embedding_count        = 0;
            params.photo_maker_path       = "";
            params.vae_decode_only        = false;
            params.free_params_immediately = false;   // keep loaded for speed
            params.n_threads              = 4;         // 4 threads on mobile
            params.wtype                  = SD_TYPE_F16;
            params.rng_type               = STD_DEFAULT_RNG;
            params.sampler_rng_type       = STD_DEFAULT_RNG;
            params.offload_params_to_cpu  = false;
            params.keep_clip_on_cpu       = false;
            params.keep_control_net_on_cpu = false;
            params.keep_vae_on_cpu        = false;
            params.flash_attn             = false;
            params.enable_mmap            = true;      // mmap for fast loading on mobile

            g_sd_ctx = new_sd_ctx(&params);

            if (g_sd_ctx == nullptr) {
                LOGE("Failed to load model: %s", model_path_c);
                goto cleanup;
            }
            g_loaded_model_path = model_str;
            LOGI("Model loaded successfully");
        }

        // Set up generation parameters
        sd_img_gen_params_t gen;
        sd_img_gen_params_init(&gen);

        gen.prompt          = prompt_c;
        gen.negative_prompt = neg_c;
        gen.clip_skip       = 0;   // 0 = auto
        gen.width           = width;
        gen.height          = height;
        gen.seed            = (int64_t)seed;
        gen.batch_count     = 1;
        gen.strength        = 1.0f;
        gen.loras           = nullptr;
        gen.lora_count      = 0;

        // Sample params
        gen.sample_params.sample_method                   = EULER_A_SAMPLE_METHOD;
        gen.sample_params.sample_steps                    = steps;
        gen.sample_params.guidance.txt_cfg                = cfgScale;
        gen.sample_params.guidance.img_cfg                = 1.0f;
        gen.sample_params.guidance.distilled_guidance     = 3.5f;
        gen.sample_params.scheduler                       = DISCRETE_SCHEDULER;
        gen.sample_params.eta                             = 0.0f;

        LOGI("Generating image %dx%d steps=%d cfg=%.1f seed=%lld", width, height, steps, cfgScale, (long long)seed);

        sd_image_t* images = generate_image(g_sd_ctx, &gen);

        if (images == nullptr) {
            LOGE("generate_image returned null");
            goto cleanup;
        }

        if (images[0].data == nullptr) {
            LOGE("generate_image returned null image data");
            free(images);
            goto cleanup;
        }

        {
            int saved = stbi_write_png(
                out_path_c,
                (int)images[0].width,
                (int)images[0].height,
                (int)images[0].channel,
                images[0].data,
                (int)(images[0].width * images[0].channel)
            );

            if (saved != 0) {
                LOGI("Image saved: %s (%dx%d)", out_path_c, images[0].width, images[0].height);
                result = JNI_TRUE;
            } else {
                LOGE("stbi_write_png failed for: %s", out_path_c);
            }
        }

        free(images[0].data);
        free(images);
    }

cleanup:
    env->ReleaseStringUTFChars(modelPath, model_path_c);
    env->ReleaseStringUTFChars(prompt, prompt_c);
    env->ReleaseStringUTFChars(negativePrompt, neg_c);
    env->ReleaseStringUTFChars(outputPath, out_path_c);
    return result;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_momoai_babymomo_bridge_ImageGenBridge_sdFreeContext(
        JNIEnv* /* env */,
        jobject /* this */) {
    freeContext();
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_momoai_babymomo_bridge_ImageGenBridge_sdGetVersion(
        JNIEnv* env,
        jobject /* this */) {
    const char* ver = sd_version();
    return env->NewStringUTF(ver ? ver : "stable-diffusion.cpp/leejet");
}
