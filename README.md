# ai-security

AI Security course content.

* **requirements/**: Installation of requirements used in exercises
* **ssh/**: SSH key generation (RSA/ed25519) and logging into a Dockerized SSH server with public-key authentication
* **attestation/**: ML model verification: SHA-256 digests, GPG signatures, cosign, and CycloneDX SBOM generation for HuggingFace models
* **breach/**: DVWA (Damn Vulnerable Web Application) lab for practising SQL injection, XSS, command injection and other common web vulnerabilities
* **pentest/**: Full penetration-testing lab with an attacker container (nmap + Metasploit), PostgreSQL, and a Metasploitable2 target on an isolated Docker network
* **pickle/**: Demonstrates how Python Pickle deserialization can inject arbitrary code into ML model files, detection with picklescan, and safer alternatives (Safetensors)
