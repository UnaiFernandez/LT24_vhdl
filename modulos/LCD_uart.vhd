--------------------------------------------------------------------------------
-- Project : LCD_vhdl
-- File    : LCD_uart.vhd
-- Autor   : Unai Fernandez
-- Date    : 2023-02-12
--
--------------------------------------------------------------------------------
-- Description : Modulo que se encarga de leer los datos que se mandan por el 
-- puerto serie.
--------------------------------------------------------------------------------

-- Declaracion librerias
library ieee;
use ieee.std_logic_1164.all;	-- libreria para tipo std_logic
use ieee.numeric_std.all;	-- libreria para tipos unsigned/signed

-- Declaracion entidad
entity lcd_uart is
    port (
	-- lista de entradas y salidas del modulo
	clk, reset: in std_logic;
	UART_TX: in std_logic;
	CHAR_CODE: out unsigned(7 downto 0);
	new_data: out std_logic
    );
end lcd_uart;

-- Declaracion de la arquitectura
architecture lcd_uart_arch of lcd_uart is

    -- declaracion de tipos y señales internas del sistema
    type tipo_estado is (e0, e1, e2, e3, e4, e5, e6);
    signal epres,esig: tipo_estado;

    signal MUX_STIME, LD_SAMP, LD_BITS, LD_RDESP, DEC_SAMP, DESP_DER, DEC_BITS : std_logic;

	signal DONE_SAMP, DONE_BITS: std_logic;
	
	signal BITS: unsigned(3 downto 0);
	signal SAMP: unsigned(12 downto 0);
    signal DATA: unsigned(7 downto 0);
    signal S_TIME: unsigned(12 downto 0);
	 
	 signal ndat: std_logic;

    begin
  
    ----------------------------------------
    ------ UNIDAD DE CONTROL ---------------
    ----------------------------------------

    -- proceso sincrono que actualiza el estado en flanco de reloj. Reset asincrono.
    process (clk,reset)
      begin
        if reset='1' then epres<=e0;
          elsif clk'event and clk='1' then epres<=esig;
        end if;
    end process;
    
    -- proceso combinacional que determina el valor de esig (estado siguiente)
    process (epres, UART_TX, DONE_SAMP, DONE_BITS)
    begin
        case epres is 
            -- una clausula when por cada estado posible
              when e0 => if (UART_TX = '0') then esig <= e1;
						else esig <= e0;
						end if;
              when e1 => esig <= e2;
              when e2 => if DONE_SAMP = '1' then esig <= e3;
                        else esig <= e2;
                        end if;
              when e3 => esig <= e4;
              when e4 => if DONE_SAMP = '1' then esig <= e5; 
                        else esig <= e4;
                        end if;
              when e5 => if DONE_BITS = '0' then esig <= e4;
                        else esig <= e6;
                        end if;
              when e6 => if UART_TX = '0' then esig <= e6;
              			else esig <= e0;
              			end if;
        end case;
    end process;

    -- una asignacion condicional para cada señal de control que genera la UC

    MUX_STIME <= '1' when epres = e1 else '0';
    LD_SAMP <= '1' when epres = e1 or epres = e3 or epres = e5 else '0';
    LD_RDESP <= '1' when epres = e1 else '0';
    LD_BITS <= '1' when epres = e1 else '0';
    DEC_SAMP <= '1' when (epres = e2 and DONE_SAMP = '0') or (epres = e4 and DONE_SAMP = '0') else '0';
    DESP_DER <= '1' when epres = e5 and DONE_BITS = '0' else '0';
    DEC_BITS <= '1' when epres = e5 and DONE_BITS = '0' else '0';
	 ndat <= '1' when epres = e6 and UART_TX = '1' else '0';
    
    ----------------------------------------
    ------ UNIDAD DE PROCESO ---------------
    ----------------------------------------

    -- codigo apropiado para cada uno de los componentes de la UP
    --  --Contadores
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
	    if (LD_SAMP='1') then SAMP<=S_TIME;
	    elsif (DEC_SAMP='1') then SAMP<=SAMP-1;
    	    end if;
          end if;
      end process;
      
      DONE_SAMP <= '1' when SAMP = "000000000000" else '0';
      
       process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
	    if (LD_BITS='1') then BITS<="1000";
	    elsif (DEC_BITS='1') then BITS<=BITS-1;
    	    end if;
          end if;
      end process;

      -- Comparador
      DONE_BITS <= '1' when BITS = "0000" else '0';
    
    -- Registro de desplazamiento
   process (clk)
	begin
		if clk'event and clk='1' then
			if LD_RDESP='1' then DATA<="00000000";
			elsif DESP_DER='1' then DATA(6 downto 0)<=DATA(7 downto 1);
				DATA(7)<= UART_TX;
			end if;
		end if;
end process;
    

    -- Multiplexor para el color
    S_TIME <= "0101000101100" when MUX_STIME = '1' else "1010001011000";
    
    
    CHAR_CODE <= DATA;
	 new_data <= ndat;
end lcd_uart_arch;


