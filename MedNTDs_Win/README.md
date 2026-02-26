
# 🖥️ Usage Guide

---

## ⚠️ Windows Permission Notice

If the application is forcibly closed on Windows, it is due to a permission issue, and you must allow program access.

This happens because the application requires permission for loading images, loading models, and saving images. Without proper access rights, Windows will force the application to close.

<img width="2538" height="1430" alt="1" src="https://github.com/user-attachments/assets/2f7a3b0e-120a-481f-8bfe-e95a3d82134d" />

---

## 📂 How to Load GGUF Models

When you click **"Load GGUF"**, three file selection dialogs will appear.

### 1️⃣ First  
Select the base quantized GGUF model  
(for example: `medgemma-1.5-4b-it-Q4_K_M.gguf`)

<img width="2538" height="1430" alt="2" src="https://github.com/user-attachments/assets/248895f6-63f9-4906-b334-7207ceff25ce" />


### 2️⃣ Second  
Select the mmproj.gguf model  
(for example: `MedNTDs_mmproj.gguf`)

<img width="2538" height="1430" alt="3" src="https://github.com/user-attachments/assets/4d81f53b-0c9e-45a0-b8fa-fe6e21eca8ae" />


### 3️⃣ Third  
Select the LoRA adapter `.gguf` model  
(for example: `MedNTDs_LoRA.gguf`)

<img width="2538" height="1430" alt="4" src="https://github.com/user-attachments/assets/a4e245b8-386c-419e-8dbd-f0e5988f145e" />


---

## 🤖 Running Inference

Once the model loading is complete, you can either:

- Take a photo using the laptop camera  
- Upload an image  

The model will automatically perform 2-step inference.

<img width="2538" height="1430" alt="5" src="https://github.com/user-attachments/assets/0d203719-5b24-45d7-b80c-eae160da6fb6" />


---

## 📊 Viewing Results

The inference results will appear on the right side of the interface.

<img width="2538" height="1429" alt="6" src="https://github.com/user-attachments/assets/9741b3da-ed47-4cb1-acd3-bae4c74ad910" />


The history is also saved.  
To view previous results, click the **History** button in the top-right corner.

<img width="2538" height="1429" alt="7" src="https://github.com/user-attachments/assets/4a0ad109-dab4-43a5-b0c7-67247957f428" />

---

## 📝 Note

All MedNTDs models (GGUF, LoRA adapters, and related files) are available on the Hugging Face repository:

👉 [https://huggingface.co/wlsgusjjn/MedNTDs](https://huggingface.co/wlsgusjjn/MedNTDs/tree/main)
