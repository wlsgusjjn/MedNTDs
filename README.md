# 🩺 MedNTDs  
### AI for Early Detection of Neglected Tropical Diseases (NTDs)

---

# 📌 Problem statement

## 🌍 Problem domain

Sub-Saharan Africa bears nearly 40% of the global burden of Neglected Tropical Diseases (NTDs). Diseases such as Buruli Ulcer, Leprosy, and Yaws frequently begin with visible skin lesions that are painless, slow-progressing, and easily overlooked.

According to the World Health Organization, more than 1.7 billion people require NTD interventions annually. In many rural areas, the doctor-to-patient ratio is often below 1:10,000, and access to specialized care is extremely limited.

The critical gap lies in early-stage recognition. Although many NTDs are curable when detected early, delayed identification often results in permanent disability, social stigma, and economic exclusion. Patients may wait weeks for visiting clinicians or travel long distances before receiving medical evaluation.

---

## 🚀 Impact potential

MedNTDs introduces AI-enabled early-stage screening support at the community level. By analyzing visible skin patterns and contextual symptoms, the system assists in identifying cases that warrant further medical attention.

This shifts the paradigm from “Waiting for a Doctor” to earlier identification and action, particularly in regions where healthcare access is intermittent.

Deployment in schools, kiosks, and community centers enables continuous availability — not as a replacement for clinicians, but as a scalable layer of preliminary assessment.

**Impact Estimation:** For conditions such as Buruli Ulcer, early-stage intervention can reduce treatment costs by over 70% per patient by avoiding surgery and prolonged hospitalization. If early-stage identification increases by just 20%, hundreds of thousands of children in endemic regions could avoid preventable disability.

MedNTDs strengthens the pathway from symptom appearance to clinical care — reducing delays that currently determine long-term outcomes.

---

# 🧠 Overall solution

<img width="1248" height="746" alt="MedNTDs_architecture" src="https://github.com/user-attachments/assets/62c80ccd-dbeb-455e-aad0-3df0568e4138" />

This system operates as a two-stage AI pipeline built on MedGemma. MedGemma belongs to Google's Health AI Developer Foundations initiative and is pre-trained on medically curated corpora.

Its training includes exposure to clinical terminology and dermatology-relevant image-text pairs, including datasets such as SCIN (Skin Condition Image Network), which focuses on diverse skin tone representation.

Compared to general VLMs, this provides:

- Better familiarity with medical vocabulary  
- Improved alignment with clinical description formats  
- More structured reasoning in health-related prompts  

However, the model does not replace clinical evaluation and is limited by training data scope..

---

## 🔎 Stage 1: Image-Based Disease Hypothesis

A fine-tuned MedGemma model analyzes the input image and produces a likely condition label within a predefined NTD scope (e.g., Buruli ulcer, cutaneous leishmaniasis, leprosy, mycetoma, scabies, tungiasis, yaws, lymphatic filariasis).

This output is treated as a preliminary model hypothesis, not a confirmed diagnosis.

Fine-tuning was performed using LoRA adaptation (Unsloth framework) on a curated dataset of skin-manifesting NTD images to improve task alignment within this restricted disease set.

Importantly, the model is not expected to perfectly differentiate subtle dermatological conditions; it functions within probabilistic pattern recognition limits.

---

## 📘 Stage 2: Guideline-Grounded Explanation

If a matching WHO-derived text asset exists for the predicted condition, the system loads a distilled clinical reference file containing:

- Early symptoms  
- Typical skin manifestations  
- Infection prevention  
- Care-seeking guidance  

The model is then prompted a second time using:

- The initial observation output  
- The structured WHO-derived text  
- Explicit instructions to avoid definitive diagnosis  

The second-stage prompt requires the model to:

- Describe visible skin features and anatomical locations.  
- Correlate observations with the provided guideline text.  
- Avoid diagnostic certainty.  

This two-stage structure ensures that MedGemma is not used as an unconstrained generative model, but as a clinically contextualized reasoning engine within a defined NTDs scope. The first stage narrows the hypothesis space through targeted fine-tuning, while the second stage constrains explanatory output using authoritative guideline content. This design reduces unsupported medical speculation while maintaining structured, medically aligned responses suitable for early-stage community screening support.

---

# ⚙️ Technical details

## 🧪 A. Model Fine-tuning

We addressed the "Data Scarcity" problem in NTDs by creating a synthetic and augmented dataset. Using Unsloth/LoRA, we achieved a significant performance boost in diagnostic accuracy compared to the pre-trained MedGemma model.

We conducted a comprehensive optimization study using Unsloth (LoRA) to adapt MedGemma for NTD (Neglected Tropical Diseases) identification. Our primary focus was achieving a balance between high sensitivity for screening and robust generalization.

### a. Screening Performance: Disease vs. Normal

The most critical task for our application is the initial screening—distinguishing any skin abnormality from healthy skin.  

<img width="924" height="396" alt="Test chart 2" src="https://github.com/user-attachments/assets/41984f63-b627-465b-a382-19f9a4bde30d" />

Disease 50% vs. Normal skin 50%

<img width="1441" height="193" alt="Test rs 2" src="https://github.com/user-attachments/assets/4b23e883-970c-4b1b-8582-8a2321fbf856" />

Analysis: Our final model achieved a ~20.3% absolute increase in Accuracy and a ~20.2% increase in Recall compared to the pre-trained MedGemma. High Recall (97.9%) is vital in medical contexts to ensure that potential cases are not missed during initial screening.

### b. Differential Diagnosis: NTDs vs. Others vs. Normal

To provide actionable advice, the model must distinguish specialized NTDs from other common skin conditions.

<img width="924" height="397" alt="Test chart 1" src="https://github.com/user-attachments/assets/d0c1f26c-297c-40c9-8a7e-9b7bb825f817" />

<img width="1441" height="155" alt="Test rs 1" src="https://github.com/user-attachments/assets/2aee80df-99f9-4f7b-9147-8bf94b9f0f1d" />

We selected the LoRA Epoch 1 configuration as our final deployment model for the following reasons:

- Superior Binary Screening: While this model was not the top performer in every sub-class, it achieved the highest scores in binary classification (Normal vs. Abnormal).  
- Prioritizing Recall for Safety: Our primary goal is early detection. We prioritized Recall to ensure that early-stage lesions are not missed; in a clinical triage setting, a conservative referral is far safer than a false negative.  
- Stable Generalization: With a validation loss of 0.057, this model demonstrated the most stable performance, suggesting better robustness against environmental biases like varied lighting and skin tones in real-world clinic settings.  

---

## 🏗 B. Application Stack

- **Frontend:** Flutter (Cross-platform UI)  
- **Inference Engine:** llama.cpp & clip.cpp (Quantized GGUF for edge computing)  
- **Backend Bridge:** Custom C++ Native Bridge (FFI) for high-performance memory management.  

---

## 🛠 C. Deployment Challenges & Solutions

### Data Feasibility: Overcoming NTD Data Scarcity

Neglected Tropical Diseases (NTDs) suffer from a critical lack of public datasets—a "data desert." We overcame this by custom-curating a specialized dataset. To ensure reliability in real-world African settings, we applied data augmentation, focusing on diverse skin tones and varied lighting conditions. This process moved the project beyond benchmarking, achieving high clinical robustness in underrepresented demographics.

### System Feasibility: High-Performance Edge Inference

To enable internet-independent operation in rural clinics, we developed a Custom C++ Native Bridge for llama.cpp. A key innovation was the implementation of Image Embedding Reuse within our 2-stage pipeline. By caching and reusing embeddings instead of re-encoding them for each prompt, we reduced memory overhead and improved inference speed by over 40% on low-spec Windows kiosks, ensuring feasibility for edge deployment.

### Architectural Feasibility: Safety-First Grounded Reasoning

To mitigate LLM hallucinations in medical contexts, we designed a WHO Guideline-Grounded 2-Step Architecture. Stage 1 identifies the condition using a fine-tuned LoRA adapter, while Stage 2 injects distilled clinical guidelines as context. By forcing the model to cross-reference observations with authoritative texts, we constrained its output to medically aligned reasoning, transforming MedGemma into a reliable, "Safety-First" community screening tool.

---

# 🌎 Conclusion: Bridging the Gap in Global Health

MedNTDs is more than just a technical demonstration; it is a scalable solution designed for the 1.7 billion people at risk of Neglected Tropical Diseases (NTDs). By harmonizing the medical expertise of the MedGemma HAI-DEF model with the accessibility of on-device edge computing, we have created a tool that functions where the internet fails and doctors are absent.

Our journey—from custom-curating an NTD dataset to optimizing 4-bit quantized inference for offline environments—reflects a commitment to Product Feasibility and real-world impact. Our deployment roadmap via Windows-based kiosks provides an immediate, actionable path to aid rural healthcare workers today. We believe that by catching skin diseases in their infancy, we are not just providing a diagnosis; we are preventing lifelong disability and fostering healthcare equity for the most vulnerable populations on Earth.
