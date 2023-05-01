--------------------------------------------------------------------------------
-- Project : LCD_uart
-- File    : LCD_drawing.vhd
-- Autor   : Unai Fernandez
-- Date    : 2023-02-5
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
entity lcd_drawing is
    port (
	-- lista de entradas y salidas del modulo
	clk, reset: in std_logic;
    DEL_SCREEN, DRAW_FIG: in std_logic;
	COLOUR_CODE: in unsigned(2 downto 0);
	DONE_CURSOR: in std_logic;
	DONE_COLOUR: in std_logic;
	RXCOL: in unsigned(7 downto 0);
	RYROW: in unsigned(8 downto 0);
    DONE_DRAW: out std_logic;
	OP_SETCURSOR, OP_DRAWCOLOR: out std_logic;
	XCOL: out unsigned(7 downto 0);
	YROW: out unsigned(8 downto 0);
    RGB: out unsigned(15 downto 0);
	NUM_PIX: out unsigned(16 downto 0)
	
    );
end lcd_drawing;

-- Declaracion de la arquitectura
architecture lcd_drawing_arch of lcd_drawing is

    -- declaracion de tipos y señales internas del sistema
    type tipo_estado is (e0, e1, e2, e3, e4, e5);
    signal epres,esig: tipo_estado;

    signal LD_FILA, SEL_DEL, SEL_DRAW, LD_CODE, OP_SETCURSORaux, OP_DRAWCOLORaux, INC_FILA, DRAW, FIN_FILA, BUTTON : std_logic;

    signal FILA: unsigned(8 downto 0);
	 signal YROWaux: unsigned(8 downto 0);
    signal Q: unsigned(2 downto 0);
    signal XCOLaux: unsigned(7 downto 0);
    signal RGBaux: unsigned(15 downto 0);
    signal NUM_PIXaux: unsigned(16 downto 0);
	 
	 signal SUM_FILA: unsigned(8 downto 0);
     signal DONE_DRAW_aux: std_logic;

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
    process (epres, DONE_CURSOR, DONE_COLOUR, DRAW, FIN_FILA, BUTTON, DEL_SCREEN, DRAW_FIG)
    begin
        case epres is 
            -- una clausula when por cada estado posible
              when e0 => if ( DEL_SCREEN = '1') then esig <= e1;
			elsif (DEL_SCREEN = '0' and DRAW_FIG = '1') then esig <= e1;
			else esig <= e0;
			end if;
              when e1 => esig <= e2;
              when e2 => if DONE_CURSOR = '1' then esig <= e3;
                        else esig <= e2;
                        end if;
              when e3 => esig <= e4;
              when e4 => if DONE_COLOUR = '0' then esig <= e4;
                        elsif (DONE_COLOUR = '1' and DRAW = '1' and FIN_FILA = '0') then esig <= e1;
								else esig <= e5;
                        end if;
              when e5 => if BUTTON = '1' then esig <= e0;
                        else esig <= e5;
                        end if;
        end case;
    end process;

    -- una asignacion condicional para cada señal de control que genera la UC

    LD_FILA <= '1' when (epres = e0 and DEL_SCREEN = '1') or (epres = e0 and DEL_SCREEN = '0' and DRAW_FIG = '1')else '0';
    SEL_DEL <= '1' when epres = e0 and DEL_SCREEN = '1' else '0';
    SEL_DRAW <= '1' when (epres = e0 and DEL_SCREEN = '0' and DRAW_FIG = '1') else '0';
    LD_CODE <= '1' when (epres = e0 and DEL_SCREEN = '1') or (epres = e0 and DEL_SCREEN = '0' and DRAW_FIG = '1') else '0';
    OP_SETCURSORaux <= '1' when epres = e1 else '0';
    OP_DRAWCOLORaux <= '1' when epres = e3 else '0';
    INC_FILA <= '1' when epres = e4 and DONE_COLOUR = '1' and DRAW = '1' and FIN_FILA = '0' else '0';
    BUTTON <= '1' when (DEL_SCREEN = '0' and DRAW_FIG = '0') else '0';

    DONE_DRAW_aux <= '1' when epres = e5 and BUTTON = '1' else '0';

    ----------------------------------------
    ------ UNIDAD DE PROCESO ---------------
    ----------------------------------------

    -- codigo apropiado para cada uno de los componentes de la UP
    --  --Contadores
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
	    if (LD_FILA='1') then FILA<=RYROW;
	    elsif (INC_FILA='1') then FILA<=FILA+1;
    	    end if;
          end if;
      end process;

      -- Comparador
      --FIN_FILA <= '1' when FILA = "001100100" else '0';
		SUM_FILA <= RYROW + 5;
		FIN_FILA <= '1' when FILA = SUM_FILA else '0';
    
    -- Registro de velocidad
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_CODE='1') then Q<=COLOUR_CODE;
    	    end if;
          end if;
    end process;
    

    process (clk, reset)
    begin
        if clk'event and clk = '1' then
            if(SEL_DRAW = '1' and SEL_DEL = '0') then DRAW <= '1' ;
            elsif(SEL_DRAW = '0' and SEL_DEL = '1') then DRAW <= '0';
            elsif (SEL_DRAW = '0' and SEL_DEL = '0') then DRAW <= DRAW;
            end if;
	end if;
    end process;

    -- Multiplexor para el color
    RGBaux <= (15 downto 11 => Q(2), 10 downto 5 => Q(1), 4 downto 0 => Q(0));
    -- Multiplexor para columnas 
    --XCOLaux <= "01100100" when DRAW = '1' else "00000000"; 
	 XCOLaux <= RXCOL when DRAW = '1' else "00000000";
	 --YROWaux <= "001100100" when DRAW = '1' else "000000000";
    -- Multiplexor para pixeles 
    --NUM_PIXaux <= "00000000001100100" when DRAW = '1' else "10010110000000000";
	 NUM_PIXaux <= "00000000000000101" when DRAW = '1' else "10010110000000000";


    XCOL <= XCOLaux;
    NUM_PIX <= NUM_PIXaux;
    YROW <= FILA;
    RGB <= RGBaux;
	 OP_SETCURSOR <= OP_SETCURSORaux;
	 OP_DRAWCOLOR <= OP_DRAWCOLORaux;

     DONE_DRAW <= DONE_DRAW_aux;
	 
end lcd_drawing_arch;


