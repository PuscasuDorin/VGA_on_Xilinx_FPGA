<!-- Pentru a face scrisul alb -->

<style>
  /* Stilul pentru ecran și browser */
  :root {
    color-scheme: dark;
  }
  body {
    background-color: #0d1117 !important;
    color: #e6edf3 !important;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    padding: 30px;
  }

  /* Regulă strictă pentru salvarea în PDF (Print) */
  @media print {
    html, body {
      background-color: #0d1117 !important;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    
    /* Forțează absolut toate textele, titlurile, celulele și lista să rămână albe/deschise */
    body, p, h1, h2, h3, h4, h5, h6, li, td, th, span, div, figcaption, b, strong {
      color: #e6edf3 !important;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }

    /* Ajustează bordurile tabelelor pentru a fi vizibile pe fundal închis */
    table, th, td {
      border-color: #30363d !important;
    }
  }
</style>

<!-- Pentru a face background-ul negru -->
<style>
  :root {
    color-scheme: dark;
  }
  body {
    background-color: #0d1117 !important; /* Culoarea de fundal Dark */
    color: #c9d1d9 !important;            /* Culoarea textului principal */
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    padding: 30px;
  }
  /* Păstrează fundalul la salvarea în PDF */
  @media print {
    body {
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
      background-color: #0d1117 !important;
    }
  }
</style>

# FPGA Video Surveillance System with PIR Motion Detection & VGA Intruder Alert
### Autor: Pușcașu Dorin
<!--# Sistem de Supraveghere Video pe FPGA cu Detecție PIR și Alertă VGA-->
---

## Istoric Revizii

| Versiune | Data       | Autor         | Descriere |
| :---:    | :---:      | :---:          | :---      |
| **v0.1** | 07.07.2026 | Pușcașu Dorin | *Draft*   |
| **v0.2** | 10.07.2026 | Pușcașu Dorin | *Am îmbunătățit         documentația și am implementat etapele: 2, 3, 4*    |
| **v0.3** | 23.07.2026 | Pușcașu Dorin | *Am îmbunătățit         documentația și am implementat etapele: 5, 6*    |

---

<figure style="text-align: center;">
  <img src="doc/electric_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption><b>Fig. 1:</b> Schema electrica</figcaption>
</figure>

---
<figure style="text-align: center;">
  <img src="doc/modules_block_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption><b>Fig. 2:</b> Arhitectura Sistemului OV7670 - VGA</figcaption>
</figure>

---

<table align="center" style="border: none; border-collapse: collapse; margin: 0 auto;">
  <tr style="border: none;">
    <td align="center" style="border: none;">

| Resource | Utilization | Available | Utilization % |
| :--- | :---: | :---: | :---: |
| **LUT** | 520 | 20800 | 2.50 |
| **FF** | 163 | 41600 | 0.39 |
| **BRAM** | 19 | 50 | 38.00 |
| **DSP** | 2 | 90 | 2.22 |
| **IO** | 35 | 106 | 33.02 |
| **BUFG** | 3 | 32 | 9.38 |
| **MMCM** | 1 | 5 | 20.00 |

<br>

<img src="doc/FPGA_timing.png" alt="FPGA Setup Timing" width="400">

  </td>
  </tr>
</table>

---

##  Cuprins
- [FPGA Video Surveillance System with PIR Motion Detection \& VGA Intruder Alert](#fpga-video-surveillance-system-with-pir-motion-detection--vga-intruder-alert)
    - [Autor: Pușcașu Dorin](#autor-pușcașu-dorin)
  - [Istoric Revizii](#istoric-revizii)
  - [Cuprins](#cuprins)
  - [Obiectivele Proiectului](#obiectivele-proiectului)
    - [Obiectiv General](#obiectiv-general)
    - [Obiectiv Personal](#obiectiv-personal)
  - [Etapa 1 - Documentația proiectului](#etapa-1---documentația-proiectului)
  - [Etapa 2 - Proiectarea și simularea controlerului VGA](#etapa-2---proiectarea-și-simularea-controlerului-vga)
  - [Etapa 3 - Implementarea pe hardware](#etapa-3---implementarea-pe-hardware)
  - [Etapa 4 - Afișarea și mișcarea unui obiect pe ecran](#etapa-4---afișarea-și-mișcarea-unui-obiect-pe-ecran)
  - [Etapa 5 - Proiectarea și realizarea unui PMOD Shield custom pentru Basys 3 (Camera + PIR)](#etapa-5---proiectarea-și-realizarea-unui-pmod-shield-custom-pentru-basys-3-camera--pir)
  - [Etapa 6 - Integrarea camerei și afișarea imaginilor](#etapa-6---integrarea-camerei-și-afișarea-imaginilor)
  - [Etapa 7 - Interfațarea senzorului de mișcare](#etapa-7---interfațarea-senzorului-de-mișcare)
  - [Etapa 8 (Bonus) - Trimiterea imaginii captate prin UARTv la PC](#etapa-8-bonus---trimiterea-imaginii-captate-prin-uartv-la-pc)

---

## Obiectivele Proiectului

### Obiectiv General
* **Implementarea etapizată a unui controler VGA** cu rezoluția baseline de **640x480**.
* **Afișarea dinamică a unei imagini** și randarea elementelor grafice pe ecran.
* **Integrarea componentelor hardware externe**, incluzând un senzor detector de mișcare (PIR) și un modul de cameră video.

<div style="display: flex; justify-content: center; align-items: center; gap: 10px; width: 100%;">
  <img src="doc/final1.jpg" alt="final1" style="width: 380px !important; height: 320px !important; object-fit: cover; display: block;" />
  <img src="doc/final2.jpg" alt="final2" style="width: 220px !important; height: 320px !important; object-fit: cover; display: block;" />
</div>

---

### Obiectiv Personal
* **Înțelegerea fundamentală a modului în care funcționează protocolul de sincronizare VGA și dobândirea de experiență practică în proiectarea, simularea și testarea sistemelor digitale complexe folosind limbajul Verilog.**

---
## Etapa 1 - Documentația proiectului 
* **Obiectiv:** Definirea temei, a cerințelor funcționale și proiectarea arhitecturii de ansamblu a sistemului pe FPGA, având ca repere:
* **Documentarea protocoalelor de comunicație:** SCCB pentru configurarea camerei OV7670 și standardul VGA pentru generarea semnalelor de sincronizare (`Hsync`, `Vsync`).
* **Dimensionarea memoriei interne Block RAM (BRAM)** în raport cu rezoluția imaginii (QVGA) și formatul de reprezentare a pixelilor.
* **Proiectarea schemei bloc de nivel înalt (Top-Level)** și definirea interfețelor dintre module (captură, memorie, afișare, achiziție senzor PIR și gestiune ceasuri).

---

## Etapa 2 - Proiectarea și simularea controlerului VGA
* **Obiectiv:** Crearea logicii în Verilog pentru semnalele de sincronizare VGA la rezoluția baseline de 640x480 @ 60Hz și verificarea lor în simulator.
* **Realizare:** Am implementat numărătoarele pentru axele orizontală (`h_count`) și verticală (`v_count`), am generat semnalele active-low `h_sync` și `v_sync` și am folosit un banc de teste (testbench) pentru a vizualiza formele de undă.
* **Dificultăți:** Erori de testbench: sincornizare si reset.
* **Mod de rezolvare:** Am efectuat un proces de debugging pe codul Verilog pentru a identifica liniile problematice. Am corectat erorile de logică din modulele de sincronizare pentru semnalele `h_sync` și `v_sync`, asigurând temporizarea corectă cerută de monitor. De asemenea, am remediat comportamentul la reset prin includerea explicită a canalului de culoare Roșu în starea de inițializare.

---

## Etapa 3 - Implementarea pe hardware
* **Obiectiv:** Sintetizarea proiectului în Vivado, maparea pinilor fizici și afișarea unei culori pe un monitor VGA real.
* **Realizare:** Am creat un Block Design în Vivado, am adăugat un IP CLock Wizard pentru a genera un PLL de 25.175MHz. Am scris fișierul de constrângeri (`.xdc`) alocând pinii corespunzători ieșirilor video și de ceas. Am generat bitstream-ul și am programat placa FPGA.
* **Dificultăți:** -
* **Mod de rezolvare:** - 

<p align="center">
  <img src="doc/red_display.jpg" width="450" height="320" alt="red_display" />
</p>

---

## Etapa 4 - Afișarea și mișcarea unui obiect pe ecran
* **Obiectiv:** Desenarea unei forme geometrice (ex: un pătrat/obiect) pe ecran și implementarea unei logici cinematice pentru deplasarea acestuia.
* **Realizare:** * **Realizare:** Am creat un circuit de generare a pixelilor care verifică dacă poziția curentă (`h_count`, `v_count`) se află în interiorul coordonatelor obiectului și la fiecare cadru complet (V-Sync) obiectul se misca.
* **Dificultăți:** Initial obiectul de pe ecran nu aparea cum trebuie si dupa ce am facut obiectul sa se miste se bloca in colturi.
* **Mod de rezolvare:** Am corectat limitele geometrice (coordonatele bounding box) ale obiectului, rezolvând astfel problema distorsionării grafice. Pentru a elimina blocajele din colțuri, am ajustat condițiile de coliziune cu marginile ecranului (din partea stanga si de sus): am înlocuit testarea eronată a pixelului absolut `0` pe axele X și Y cu o limitare la primul pixel vizibil din zona activă (`1`), asigurând o schimbare fluidă a direcției de mișcare.

<p align="center">
  <img src="doc/cube.JPG" width="450" height="320" alt="cube" />
</p>

---

## Etapa 5 - Proiectarea și realizarea unui PMOD Shield custom pentru Basys 3 (Camera + PIR)
* **Obiectiv:** Proiectarea și asamblarea unui adaptor (shield) bazat pe conectori PMOD pentru placa Basys 3, cu scopul de a conecta modular, sigur și compact modulul de cameră (ex: OV7670) și senzorul de mișcare PIR.
* **Realizare:** Am proiectat schema electrică și PCB-ul adaptorului, rutați pinii de date și control ai camerei și ai senzorului direct către porturile PMOD ale plăcii Basys 3 (păstrând nivelele logice de 3.3V). Am lipit conectorii tată-mamă și am testat continuitatea traseelor înainte de alimentarea pe placă.
* **Dificultăți:** Alimentarea senzorului PIR era de 5V, iar pinii PMOD ai FPGA-ului scoteau doar 3.3V.
* **Mod de rezolvare:** Am tăiat un cablu USB A l-am legat la pinii de alimentare ai senzorului, iar celălalt capăt l-am pus în portul USB al FPGA-ului care scoate 5V.


<div style="text-align: center; display: flex; justify-content: center; gap: 1%; width: 100%;">
  <img src="doc/PMOD1.jpg" style="width: 31%; height: 200px; object-fit: cover; border: 1px solid #444; display: block;">
  <img src="doc/PMOD2.jpg" style="width: 31%; height: 200px; object-fit: cover; border: 1px solid #444; display: block;">
  <img src="doc/PMOD3.jpg" style="width: 31%; height: 200px; object-fit: cover; border: 1px solid #444; display: block;">
</div>

---

## Etapa 6 - Integrarea camerei și afișarea imaginilor
* **Obiectiv:** Preluarea unui flux video de la o cameră externă (sau imagini predefinite), stocarea datelor într-o memorie internă și randarea lor dinamică pe VGA.
* **Realizare:** Implementarea modulelor de control pentru camera OV7670 (ov7670_sccb, ov7670_init, ov7670_capture). Datele ale pixelilor recepționați de la cameră pe magistrala ov7670_data sunt capturate sincron pe frontul PCLK și stocate într-o memorie internă Dual-Port BRAM (frame_buffer). În paralel, modulul de afișare VGA (vga_controller / vga_img_display) citește adresele din BRAM sincronizat cu ceasul de afișare și randează fluxul video în timp real pe monitor.
* **Dificultăți:** Afișarea imaginii pe ecran prezenta artefacte (imagine distorsionată, culori inversate/greșite, liniamente defazate sau imagine neclară) din cauza neconcordanțelor de timing la achiziția pixelilor și a configurării greșite a formatului de ieșire al camerei.
* **Mod de rezolvare:** Am refacut implementarea protocolului SCCB, Am Ajustat tabelul de registre de inițializare a camerei (setarea formatului corect de pixeli și activarea scalării la rezoluția dorită, setarea formatului de culoare in YUV in loc de RGB) și am corectat logica din modulul ov7670_capture pentru a asambla corect cei 2 octeți corespunzători fiecărui pixel.
---
<figure style="text-align: center;">
  <img src="doc/FSM_SCCB_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption><b>Fig. 3:</b> Diagrama FSM-SCCB</figcaption>
</figure>

SCCB - Serial Camera Control Bus

---

<figure style="text-align: center;">
  <img src="doc/FSM_CAMERA_INIT_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption><b>Fig. 4:</b> Diagrama FSM_OV7670_INIT</figcaption>
</figure>


---

## Etapa 7 - Interfațarea senzorului de mișcare
* **Obiectiv:** Conectarea senzorului de mișcare (PIR) la FPGA și utilizarea stării acestuia pentru a influența memoria BRAM a FPGA-ului care stocheaza imaginea primita de la camera.
* **Realizare:** Conectarea ieșirii digitale a senzorului PIR la un pin de intrare al FPGA-ului (pir_sensor). Preluarea stării senzorului și integrarea acesteia în logica de control a sistemului pentru a acționa asupra memoriei frame_buffer (de exemplu: oprirea scrierii în BRAM pentru a „îngheța”/salva cadrul în momentul detectării mișcării sau modificarea modulului de afișare VGA).
* **Dificultăți:** -
* **Mod de rezolvare:** -

---

## Etapa 8 (Bonus) - Trimiterea imaginii captate prin UARTv la PC
* **Obiectiv:** Transmiterea datelor binare ale imaginii salvate în memoria FPGA-ului (BRAM) către un calculator, utilizând protocolul de comunicație serială UART.
* **Realizare:** -
* **Dificultăți:** - 
* **Mod de rezolvare:** - 