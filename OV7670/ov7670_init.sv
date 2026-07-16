module ov7670_init (
    input  logic       clk,           // 25.175 MHz Main Clock
    input  logic       rst_n,         // Active-low reset
    input  logic       sccb_ready,    // Input de la ov7670_sccb (ready)
    
    output logic       sccb_start,    // Output catre ov7670_sccb (start)
    output logic [7:0] sccb_reg_addr, // Output catre ov7670_sccb (reg_addr)
    output logic [7:0] sccb_reg_data, // Output catre ov7670_sccb (reg_data)
    output logic       done           // Devine 1 cand configurarea s-a terminat cu succes
);

    // Numarul total de registri din noua tabela de initializare
    localparam TOTAL_REGS = 15;

    // Masina de stari (FSM)
    typedef enum logic [2:0] {
        S_RESET_DELAY, // Asteptam ~30ms dupa comanda de reset software a camerei[cite: 1]
        S_FETCH,       // Citim urmatorul registru din ROM
        S_START_WRITE, // Generam pulsul de start pentru SCCB
        S_WAIT_READY,  // Asteptam ca modulul SCCB sa termine transmisia (ready == 1)
        S_NEXT,        // Trecem la urmatorul registru sau finalizam
        S_DONE         // Initializare terminata
    } state_t;

    state_t state;

    // Pointer catre registrul curent din ROM
    logic [3:0] reg_ptr;

    // Temporizator pentru delay-ul de reset (~30 ms la un ceas de 25.175 MHz)
    // 25.175 MHz * 30 ms = 755.250 de cicli de ceas
    logic [19:0] delay_counter;
    localparam DELAY_30MS = 20'd755250;

    // Structura pentru stocarea perechilor (Adresa, Valoare)
    typedef struct packed {
        logic [7:0] addr;
        logic [7:0] data;
    } reg_t;

    // ROM-ul cu configurarea camerei (QVGA Nativ, RGB565)[cite: 1]
    reg_t rom_regs [TOTAL_REGS];
    
    always_comb begin
        // 1. Resetare software obligatorie (așteaptă ~30ms după acest pas)[cite: 1]
        rom_regs[0]  = '{addr: 8'h12, data: 8'h80}; // COM7: Reset complet[cite: 1]
        
        // 2. Format si rezolutie (QVGA, RGB565)[cite: 1]
        rom_regs[1]  = '{addr: 8'h12, data: 8'h14}; // COM7: QVGA + RGB[cite: 1]
        rom_regs[2]  = '{addr: 8'h40, data: 8'hD0}; // COM15: RGB565 standard, full range[cite: 1]
        rom_regs[3]  = '{addr: 8'h3A, data: 8'h04}; // TSLB: Aliniere biti[cite: 1]
        
        // 3. Activare scalare hardware interna din camera (VGA -> QVGA)[cite: 1]
        rom_regs[4]  = '{addr: 8'h0C, data: 8'h08}; // COM3: Activeaza scalarea interna[cite: 1]
        rom_regs[5]  = '{addr: 8'h3E, data: 8'h19}; // COM14: Activeaza scalarea ceasului PCLK[cite: 1]
        rom_regs[6]  = '{addr: 8'h72, data: 8'h11}; // SCALING_DCWCTR: Decimare verticala/orizontala[cite: 1]
        rom_regs[7]  = '{addr: 8'h73, data: 8'hF1}; // SCALING_PCLK_DIV: Divizor ceas pixeli[cite: 1]
        
        // 4. Frecventa ceas pixeli (CLKRC divizat la 2 pentru stabilitate)[cite: 1]
        rom_regs[8]  = '{addr: 8'h11, data: 8'h01}; // CLKRC: Prescaler ceas intern[cite: 1]
        
        // 5. Corectie pozitionare fereastra (Aliniere imagine optimizata pentru scalare)[cite: 1]
        rom_regs[9]  = '{addr: 8'h17, data: 8'h16}; // HSTART[cite: 1]
        rom_regs[10] = '{addr: 8'h18, data: 8'h04}; // HSTOP[cite: 1]
        rom_regs[11] = '{addr: 8'h32, data: 8'hA4}; // HREF[cite: 1]
        rom_regs[12] = '{addr: 8'h19, data: 8'h02}; // VSTART[cite: 1]
        rom_regs[13] = '{addr: 8'h1A, data: 8'h7A}; // VSTOP[cite: 1]
        rom_regs[14] = '{addr: 8'h03, data: 8'h0A}; // VREF[cite: 1]
    end

    // FSM pentru controlul scrierii registrilor
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state         <= S_FETCH;
            reg_ptr       <= 0;
            sccb_start    <= 1'b0;
            sccb_reg_addr <= 8'h00;
            sccb_reg_data <= 8'h00;
            delay_counter <= 0;
            done          <= 1'b0;
        end else begin
            case (state)
                
                S_FETCH: begin
                    sccb_reg_addr <= rom_regs[reg_ptr].addr;
                    sccb_reg_data <= rom_regs[reg_ptr].data;
                    state         <= S_START_WRITE;
                end

                S_START_WRITE: begin
                    if (sccb_ready) begin
                        sccb_start <= 1'b1; // Generam pulsul de start
                        state      <= S_WAIT_READY;
                    end
                end

                S_WAIT_READY: begin
                    sccb_start <= 1'b0; // Coboram imediat start-ul
                    // Asteptam ca SCCB sa preia comanda si sa redevina ready
                    if (sccb_ready && !sccb_start) begin
                        // Daca am scris registrul de Reset (care este primul, la indexul 0),
                        // intram in delay-ul de 30ms ca senzorul sa reporneasca stabil[cite: 1].
                        if (reg_ptr == 0) begin
                            delay_counter <= 0;
                            state         <= S_RESET_DELAY;
                        end else begin
                            state         <= S_NEXT;
                        end
                    end
                end

                S_RESET_DELAY: begin
                    if (delay_counter >= DELAY_30MS) begin
                        state <= S_NEXT;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                S_NEXT: begin
                    if (reg_ptr == TOTAL_REGS - 1) begin
                        state <= S_DONE;
                    end else begin
                        reg_ptr <= reg_ptr + 1;
                        state   <= S_FETCH;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1; // Semnaleaza modulului principal ca initializarea s-a incheiat
                    state <= S_DONE; // Blocheaza FSM-ul aici pana la urmatorul Reset global
                end

                default: state <= S_FETCH;
            endcase
        end
    end

endmodule