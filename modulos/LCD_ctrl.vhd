--------------------------------------------------------------------------------
-- Project : LCD_uart
-- File    : LCD_ctrl.vhd
-- Autor   : Unai Fernandez
-- Date    : 2023-01-26
--
--------------------------------------------------------------------------------
-- Description : Modulo que se encarga del control de la pantalla LCD.
--
--------------------------------------------------------------------------------

-- Declaracion librerias
library ieee;
use ieee.std_logic_1164.all;	-- libreria para tipo std_logic
use ieee.numeric_std.all;	-- libreria para tipos unsigned/signed

-- Declaracion entidad
entity lcd_ctrl is
    port (
	-- lista de entradas y salidas del modulo
	clk, reset: in std_logic;
    	LCD_init_Done, OP_SETCURSOR, OP_DRAWCOLOR: in std_logic;
	XCOL: in unsigned(7 downto 0);
	YROW: in unsigned(8 downto 0);
	RGB: in unsigned(15 downto 0);
	NUM_PIX: in unsigned(16 downto 0);
	DONE_CURSOR, DONE_COLOUR, LCD_CS_N, LCD_WR_N, LCD_RS: out std_logic;
	LCD_DATA: out unsigned(15 downto 0)
	
    );
end lcd_ctrl;

-- Declaracion de la arquitectura
architecture lcd_ctrl_arch of lcd_ctrl is

    -- declaracion de tipos y señales internas del sistema
    type tipo_estado is (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12);
    signal epres,esig: tipo_estado;

    signal QDAT: unsigned(2 downto 0);
    signal END_PIX: std_logic;
    signal LD_INFO, CL_DAT, RS_COM, RS_DAT, CL_MUX, CS_N, WR_N, INC_DAT, LD_2C, DEC_PIX: std_logic;
    signal PIX: unsigned (16 downto 0);
    signal RXCOL: unsigned (7 downto 0);
    signal RYROW: unsigned (8 downto 0);
    signal RRGB: unsigned (15 downto 0);

    signal DONE_CURSORaux, DONE_COLOURaux, LCD_RSaux: std_logic;
    signal LCD_DATAaux: unsigned(15 downto 0);

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
    process (epres, LCD_init_Done, OP_SETCURSOR, OP_DRAWCOLOR, QDAT, END_PIX)
    begin
        case epres is 
            -- una clausula when por cada estado posible
              when e0 => if LCD_init_Done='1' and OP_SETCURSOR='1' then esig<=e1;
	                    elsif LCD_init_Done='1' and OP_SETCURSOR='0' and OP_DRAWCOLOR='1' then esig<=e12;
          	            else esig<=e0;
          	            end if;
              when e1 => esig <= e2;
              when e2 => esig <= e3;
              when e3 => if QDAT=5 then esig <= e9;
          	    elsif QDAT=2 then esig <= e10;
                elsif QDAT=0 or QDAT=1 or QDAT=3 or QDAT = 4 then esig <= e11;
                else esig<=e4;
		    end if;
              when e4 => esig <= e5;
              when e5 => esig <= e6;
              when e6 => esig <= e7;
              when e7 => if END_PIX='0' then esig<=e5;
                        else esig<=e8;
                        end if;
              when e8 => esig <= e0;
              when e9 => esig <= e0;
              when e10 => esig <= e2;
              when e11 => esig <= e2;
              when e12 => esig <= e2;
        end case;
    end process;

    -- una asignacion condicional para cada señal de control que genera la UC

    LD_INFO <= '1' when epres=e1 or epres=e12 else '0';
    CL_DAT <= '1' when epres=e1 else '0';
    RS_COM <= '1' when epres=e1 or epres=e10 or epres = e12 else '0';
    RS_DAT <= '1' when epres=e11 or epres=e4 else '0';
    CL_MUX <= '1' when epres=e0 or epres=e1 or epres=e12 else '0';
    CS_N <= '0' when epres=e2 or epres=e5 else '1';
    WR_N <= '0' when epres = e2 or epres=e5 else '1';
    INC_DAT <= '1' when epres=e10 or epres=e11 or epres=e4 else '0';
    LD_2C <= '1' when epres=e12 else '0';
    DEC_PIX <= '1' when epres=e6 else '0';


    DONE_CURSORaux <= '1' when epres = e9 else '0';
    DONE_COLOURaux <= '1' when epres = e8 else '0';

    ----------------------------------------
    ------ UNIDAD DE PROCESO ---------------
    ----------------------------------------

    -- codigo apropiado para cada uno de los componentes de la UP
    --  --Contadores
    process (clk, reset, CL_DAT) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if CL_DAT='1' then QDAT<="000";
    	elsif clk'event and clk='1' then 
	    if (LD_2C = '1') then QDAT<="110";
	    elsif (INC_DAT='1') then QDAT<=QDAT+1;
    	    end if;
          end if;
      end process;
    
    
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
	    if (LD_INFO='1') then PIX<=NUM_PIX;
	    elsif (DEC_PIX='1') then PIX<=PIX-1;
    	    end if;
          end if;
      end process;
      END_PIX <= '1' when PIX = 0 else '0';
    
    -- Registro de velocidad
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_INFO='1') then RXCOL<=XCOL;
    	    end if;
          end if;
    end process;
    
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_INFO='1') then RYROW<=YROW;
    	    end if;
          end if;
    end process;
    
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
	begin
    	if clk'event and clk='1' then 
    	    if (LD_INFO='1') then RRGB<=RGB;
    	    end if;
          end if;
    end process;

    -- Multiplexor
    LCD_DATAaux <= x"002A" when (CL_MUX='0' and QDAT=0) else
		x"0000" when (CL_MUX='0' and QDAT=1) else
		(x"00"&RXCOL) when (CL_MUX = '0' and QDAT=2) else
		x"002B" when (CL_MUX = '0' and QDAT=3) else
		(x"000"&"000"&RYROW(8)) when (CL_MUX='0' and QDAT=4) else
		(x"00"&RYROW(7 downto 0)) when (CL_MUX='0' and QDAT=5) else
		x"002C" when (CL_MUX='0' and QDAT=6)else
		RRGB when (CL_MUX='0' and QDAT=7) else
		x"0000"; 

    


    process (clk)
	begin
	    if (clk'event and clk='1') then
		if (RS_DAT='1' and RS_COM='0') then LCD_RSaux<='1';
		elsif (RS_DAT='0' and RS_COM='1') then LCD_RSaux<='0';
		end if;
	    end if;
    end process;


    LCD_RS<=LCD_RSaux;
    DONE_CURSOR<=DONE_CURSORaux;
    DONE_COLOUR<=DONE_COLOURaux;
    LCD_CS_N<=CS_N;
    LCD_WR_N<=WR_N;
    LCD_DATA<=LCD_DATAaux;

end lcd_ctrl_arch;


