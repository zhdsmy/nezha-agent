#!/usr/bin/env python3
"""Reject empty CA bundles and the two roots revoked in October 2026."""
import hashlib
import io
import re
import ssl
import subprocess
import sys
import tarfile

BLOCKED = {
    "86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b",
    "d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4",
}


def fingerprints(data):
    return {
        hashlib.sha256(ssl.PEM_cert_to_DER_cert(pem.decode())).hexdigest()
        for pem in re.findall(
            rb"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----", data, re.S
        )
    }


# Exercise PEM decoding and the empty-bundle boundary without a Docker daemon.
assert fingerprints(b"-----BEGIN CERTIFICATE-----\ndGVzdA==\n-----END CERTIFICATE-----") == {
    hashlib.sha256(b"test").hexdigest()
}
assert not fingerprints(b"not a certificate")

if len(sys.argv) == 1:
    print("CA parser self-check passed")
    sys.exit(0)

cid = subprocess.check_output(
    ["docker", "create", "--network", "none", "--entrypoint", "/bin/true", sys.argv[1]],
    text=True,
).strip()
try:
    bundle = subprocess.check_output(
        ["docker", "cp", "-L", cid + ":/etc/ssl/certs/ca-certificates.crt", "-"]
    )
    with tarfile.open(fileobj=io.BytesIO(bundle)) as archive:
        roots = set()
        for member in archive:
            if member.isfile():
                roots.update(fingerprints(archive.extractfile(member).read()))
    assert roots, "CA bundle is empty or unreadable"
    assert not roots & BLOCKED, "revoked October 2026 CA remains trusted"
    print(f"CA check passed: {len(roots)} certificates; revoked roots absent")
finally:
    subprocess.run(["docker", "rm", "-v", cid], check=True, stdout=subprocess.DEVNULL)
