# Pickle File Tampering Lab

## Overview

This lab demonstrates how Python's Pickle serialization format can be exploited to execute arbitrary code. Students will learn why Pickle files are a security risk in AI/ML workflows and why safer alternatives like Safetensors should be preferred.

## Objectives

By completing this lab, students will be able to:

- Understand the security risks of deserializing untrusted Pickle files
- Tamper with an existing ML model saved in Pickle format to inject malicious code
- Construct a malicious Python object that executes code upon deserialization
- Use scanning tools (`pickletools`, `picklescan`) to detect unsafe Pickle files
- Recognize that binary serialization vulnerabilities extend beyond Pickle and apply to other model/dataset formats

## Prerequisites

- Python 3.x
- Jupyter Notebook or VS Code with Jupyter extension
- Basic understanding of Python serialization and ML model persistence

## Instructions

1. Open the notebook `tampering_pickle_files.ipynb`
2. Execute each cell sequentially and observe the results

### Part 1 — Tamper with an Existing Model File

- Train a simple linear regression model using scikit-learn and save it as a `.pkl` file
- Use the `fickling` library to inject arbitrary Python code into the saved Pickle file
- Load the tampered file and observe that the injected code executes automatically during deserialization
- Inspect the tampered file with `pickletools` to see the injected payload
- Scan the file with `picklescan` to verify the malicious import is detected

### Part 2 — Construct Malicious Deserialization Code

- Create a custom Python class that overrides `__reduce__` to run arbitrary code when deserialized
- Serialize the malicious object and load it back, observing the code execution
- Scan the resulting file with `picklescan`

## Key Takeaways

- Pickle files execute arbitrary code during deserialization — **never load untrusted Pickle files**
- This vulnerability is not unique to Pickle; other binary formats for models and datasets can be affected
- Safetensors is a safer alternative that does not allow code injection
- Tools like `picklescan` can help detect known malicious patterns, but cannot guarantee catching all exploits
- Hugging Face scans uploaded Pickle files but does not remove flagged files — they are only marked as unsafe

## Dependencies

The notebook installs the following packages:

| Package | Version | Purpose |
|---|---|---|
| `pickle-mixin` | 1.0.2 | Pickle utilities |
| `fickling` | 0.1.3 | Pickle file manipulation and code injection |
| `picklescan` | 0.0.16 | Scanning Pickle files for unsafe imports |
| `scikit-learn` | (system default) | Training the example ML model |
