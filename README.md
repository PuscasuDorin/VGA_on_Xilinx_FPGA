# VGA & Sensor Integration Project
### Autor: Pușcașu Dorin
---

## Istoric Revizii

| Versiune | Data       | Autor         | Descriere |
| :---:    | :---:      | :---:          | :---      |
| **v0.1** | 07.07.2026 | Pușcașu Dorin | *Draft*   |
| **v0.2** | 10.07.2026 | Pușcașu Dorin | *Am îmbunătățit         documentația și am implementat etapele: 2, 3, 4*    |

---


##  Cuprins
- [VGA \& Sensor Integration Project](#vga--sensor-integration-project)
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
  - [Etapa 5 - Integrarea camerei și afișarea imaginilor](#etapa-5---integrarea-camerei-și-afișarea-imaginilor)
  - [Etapa 6 - Interfațarea senzorului de mișcare](#etapa-6---interfațarea-senzorului-de-mișcare)
  - [Etapa 7 (Bonus) - Trimiterea imaginii captate prin UARTv la PC](#etapa-7-bonus---trimiterea-imaginii-captate-prin-uartv-la-pc)

---

## Obiectivele Proiectului

### Obiectiv General
* **Implementarea etapizată a unui controler VGA** cu rezoluția baseline de **640x480**.
* **Afișarea dinamică a unei imagini** și randarea elementelor grafice pe ecran.
* **Integrarea componentelor hardware externe**, incluzând un senzor detector de mișcare (PIR) și un modul de cameră video.

---

### Obiectiv Personal
* **Înțelegerea fundamentală a modului în care funcționează protocolul de sincronizare VGA și dobândirea de experiență practică în proiectarea, simularea și testarea sistemelor digitale complexe folosind limbajul Verilog.**

---
## Etapa 1 - Documentația proiectului 
* **Obiectiv:** Stabilirea temei, a obiectivelor și a arhitecturii inițiale.

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

---

## Etapa 4 - Afișarea și mișcarea unui obiect pe ecran
* **Obiectiv:** Desenarea unei forme geometrice (ex: un pătrat/obiect) pe ecran și implementarea unei logici cinematice pentru deplasarea acestuia.
* **Realizare:** * **Realizare:** Am creat un circuit de generare a pixelilor care verifică dacă poziția curentă (`h_count`, `v_count`) se află în interiorul coordonatelor obiectului și la fiecare cadru complet (V-Sync) obiectul se misca.
* **Dificultăți:** Initial obiectul de pe ecran nu aparea cum trebuie si dupa ce am facut obiectul sa se miste se bloca in colturi.
* **Mod de rezolvare:** Am corectat limitele geometrice (coordonatele bounding box) ale obiectului, rezolvând astfel problema distorsionării grafice. Pentru a elimina blocajele din colțuri, am ajustat condițiile de coliziune cu marginile ecranului (din partea stanga si de sus): am înlocuit testarea eronată a pixelului absolut `0` pe axele X și Y cu o limitare la primul pixel vizibil din zona activă (`1`), asigurând o schimbare fluidă a direcției de mișcare.

---


## Etapa 5 - Integrarea camerei și afișarea imaginilor
* **Obiectiv:** Preluarea unui flux video de la o cameră externă (sau imagini predefinite), stocarea datelor într-o memorie internă și randarea lor dinamică pe VGA.
* **Realizare:** -
* **Dificultăți:** afisarea imaginii pe ecran, imaginea afisata nu arata bine
* **Mod de rezolvare:** -

<figure>
  <img src="doc/FSM_SCCB_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption align="center"><b>Fig. 1:</b> Diagrama FSM-SCCB</figcaption>
</figure>

SCCB - Serial Camera Control Bus

---

## Etapa 6 - Interfațarea senzorului de mișcare
* **Obiectiv:** Conectarea senzorului de mișcare (PIR) la FPGA și utilizarea stării acestuia pentru a influența memoria BRAM a FPGA-ului care stocheaza imaginea primita de la camera.
* **Realizare:** -
* **Dificultăți:** -
* **Mod de rezolvare:** -

---

## Etapa 7 (Bonus) - Trimiterea imaginii captate prin UARTv la PC
* **Obiectiv:** Transmiterea datelor binare ale imaginii salvate în memoria FPGA-ului (BRAM) către un calculator, utilizând protocolul de comunicație serială UART.
* **Realizare:** -
* **Dificultăți:** - 
* **Mod de rezolvare:** - 

<figure>
  <img src="doc/modules_block_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption align="center"><b>Fig. 1:</b> Diagrama FSM-SCCB</figcaption>
</figure>


<figure>
  <img src="doc/electric_diagram.png" alt="Diagrama FSM-SCCB">
  <figcaption align="center"><b>Fig. 1:</b> Diagrama FSM-SCCB</figcaption>
</figure>