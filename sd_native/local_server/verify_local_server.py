#!/usr/bin/env python3
"""
verify_local_server.py
----------------------
A lightweight verification script to ensure the integrity, size, and readability of the
dynamically downloaded libmomoimagegen.so shared library used by the local server.

Usage:
    python verify_local_server.py [--path <path_to_so_file>]
"""

import os
import sys
import argparse

# Expected properties
EXPECTED_SIZE_BYTES = 93301256  # 93.30 MB (88.98 MiB)
ELF_MAGIC = b'\x7fELF'
ELF_CLASS_64 = 2  # 64-bit
ELF_DATA_LSB = 1  # Little endian
ELF_MACHINE_AARCH64 = 0xB7  # ARM AArch64

def check_so_integrity(so_path):
    print(f"=== Verifying: {so_path} ===")
    
    # 1. Existence check
    if not os.path.exists(so_path):
        print(f"[-] Error: File does not exist at '{so_path}'")
        return False
    
    if not os.path.isfile(so_path):
        print(f"[-] Error: Path '{so_path}' is not a file")
        return False
        
    print("[+] File exists.")

    # 2. Readability check
    try:
        with open(so_path, 'rb') as f:
            # Try reading the first 64 bytes (ELF header size is 64 bytes for 64-bit ELF)
            header = f.read(64)
            if len(header) < 64:
                print("[-] Error: File is too small to be a valid ELF binary")
                return False
    except IOError as e:
        print(f"[-] Error: File is not readable. {e}")
        return False
    
    print("[+] File is readable.")

    # 3. Size check
    size_bytes = os.path.getsize(so_path)
    size_mb = size_bytes / (1024 * 1024)
    print(f"[i] Size: {size_bytes} bytes ({size_mb:.2f} MB)")
    
    if size_bytes == EXPECTED_SIZE_BYTES:
        print(f"[+] Size matches the expected {EXPECTED_SIZE_BYTES} bytes exactly.")
    else:
        # If it doesn't match exactly, check if it's close enough (e.g. within 5% or simply warn)
        diff_percent = abs(size_bytes - EXPECTED_SIZE_BYTES) / EXPECTED_SIZE_BYTES * 100
        if diff_percent < 5:
            print(f"[!] Size differs slightly from expected ({EXPECTED_SIZE_BYTES} bytes), but is within 5% tolerance.")
        else:
            print(f"[-] Error: Size mismatch. Expected ~93MB ({EXPECTED_SIZE_BYTES} bytes), but got {size_bytes} bytes.")
            return False

    # 4. Header validation (ELF check)
    magic = header[0:4]
    if magic != ELF_MAGIC:
        print(f"[-] Error: Invalid ELF magic. Expected {ELF_MAGIC}, but got {magic}")
        return False
    print("[+] ELF magic signature verified.")

    # ELF Class (32-bit vs 64-bit)
    elf_class = header[4]
    if elf_class == ELF_CLASS_64:
        print("[+] Binary class: 64-bit")
    else:
        print(f"[!] Warning: Binary class is {elf_class} (Expected 2 for 64-bit)")

    # Data encoding (Endianness)
    elf_data = header[5]
    if elf_data == ELF_DATA_LSB:
        print("[+] Endianness: Little Endian")
    else:
        print(f"[!] Warning: Endianness is {elf_data} (Expected 1 for Little Endian)")

    # Machine architecture (AArch64 / ARM64)
    # Machine type is at offset 18 (2 bytes, e18-e19 in ELF header)
    # Using little endian format
    machine = header[18] | (header[19] << 8)
    if machine == ELF_MACHINE_AARCH64:
        print("[+] Target architecture: AArch64 (ARM64)")
    elif machine == 0x28:
        print("[+] Target architecture: ARM (32-bit)")
    else:
        print(f"[i] Target architecture machine code: 0x{machine:02X}")

    print("[+] Integrity check PASSED successfully.")
    return True

def main():
    parser = argparse.ArgumentParser(description="Verify libmomoimagegen.so integrity.")
    parser.add_argument(
        "--path", 
        type=str, 
        default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "libmomoimagegen.so"),
        help="Path to libmomoimagegen.so file"
    )
    args = parser.parse_args()
    
    success = check_so_integrity(args.path)
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
