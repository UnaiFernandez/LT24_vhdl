 library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mirom_pkg.all;

entity DE10_Standard_LCD_ctrl_test is
 port(
	-- CLOCK ----------------
	CLOCK_50	: in	std_logic;
--	CLOCK2_50	: in	std_logic;
--	CLOCK3_50	: in	std_logic;
--	CLOCK4_50	: in	std_logic;
	-- KEY ----------------
--	KEY 		: in	std_logic_vector(0 downto 0);
	KEY 		: in	std_logic_vector(3 downto 0);
	-- LEDR ----------------
--	LEDR 		: out	std_logic_vector(9 downto 0);
	-- SW ----------------
	SW 			: in	std_logic_vector(9 downto 0);
	-- GPIO-LT24-UART ----------
	-- LCD --
 LT24_LCD_ON 	: out	std_logic;
 LT24_RESET_N	: out	std_logic;
 LT24_CS_N		: out	std_logic;
 LT24_RD_N		: out	std_logic;
 LT24_RS			: out	std_logic;
 LT24_WR_N		: out	std_logic;
 LT24_D			: out	std_logic_vector(15 downto 0);
	-- UART --
	B: out std_logic;
	UART_RX		: in	std_logic

	--- Pruebas 
	-- 7-SEG ----------------
--	HEX0	: out	std_logic_vector(6 downto 0);
--	HEX1	: out	std_logic_vector(6 downto 0);
--	HEX2	: out	std_logic_vector(6 downto 0);
--	HEX3	: out	std_logic_vector(6 downto 0);
--	HEX4	: out	std_logic_vector(6 downto 0);
--	HEX5	: out	std_logic_vector(6 downto 0);

); -- ***OJO*** ultimo de la lista sin ;

end;

architecture rtl of DE10_Standard_LCD_ctrl_test is 
	signal clk, reset, reset_l   : std_logic;
	
	component LT24Setup 
 port(
      -- CLOCK and Reset_l ----------------
      clk            : in      std_logic;
      reset_l        : in      std_logic;

      LT24_LCD_ON      : out std_logic;
      LT24_RESET_N     : out std_logic;
      LT24_CS_N        : out std_logic;
      LT24_RS          : out std_logic;
      LT24_WR_N        : out std_logic;
      LT24_RD_N        : out std_logic;
      LT24_D           : out std_logic_vector(15 downto 0);

      LT24_CS_N_Int        : in std_logic;
      LT24_RS_Int          : in std_logic;
      LT24_WR_N_Int        : in std_logic;
      LT24_RD_N_Int        : in std_logic;
      LT24_D_Int           : in std_logic_vector(15 downto 0);
      
      LT24_Init_Done       : out std_logic
 );
end component;

component lcd_ctrl is
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
end component;

component lcd_drawing is
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
end component;

component lcd_uart is
    port (
	-- lista de entradas y salidas del modulo
	clk, reset: in std_logic;
	UART_TX: in std_logic;
	CHAR_CODE: out unsigned(7 downto 0);
	new_data: out std_logic
    );
end component;

component rom_chars 
  port (
    clk         : in  std_logic;
    addr        : in  std_logic_vector(15 downto 0);
    datout      : out std_logic_vector(3 downto 0)
  );
  end component;


    -- declaracion de tipos y señales internas del sistema
    type tipo_estado is (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11);
    signal epres,esig: tipo_estado;

signal init_done: std_logic;
signal cs_n: std_logic;
signal wr_n: std_logic;
signal rs: std_logic;
signal tx: std_logic;

signal d: unsigned(15 downto 0);
signal ciclos: unsigned(18 downto 0);
signal pos: unsigned(7 downto 0);
signal rgb: unsigned(15 downto 0);

signal yr: unsigned(8 downto 0);
signal xc: unsigned(7 downto 0);
signal npix: unsigned(16 downto 0);
signal code: unsigned(7 downto 0);

signal done_cur, done_col, set_cur, draw_col: std_logic; 
signal col_code: unsigned(2 downto 0);

------------------------------------------------

signal LD_ADDR, LD_CONT, LD_CMEM, INC_CONT, INC_CMEM, new_data, FIN_CONT, FIN_CMEM, DONE: std_logic;

signal CONT: unsigned (2 downto 0);
signal CMEM: unsigned (15 downto 0);
signal MAX_CMEM: unsigned (15 downto 0);
signal ADDR: unsigned (15 downto 0);
signal RADDR: unsigned (15 downto 0);
signal ROM_data: std_logic_vector (3 downto 0);
signal ROM_data_aux: std_logic;

-------------------------------------------------

signal SEL_INIX, SEL_INIY, SEL_NXCOL, SEL_NYROW, LD_NXCOL, LD_NYROW, LD_RXCOL, LD_RYROW, LD_CYROW, SEL_CYROW: std_logic;
signal NXCOL: unsigned(7 downto 0);
signal NYROW: unsigned(8 downto 0);
signal RXCOL: unsigned(7 downto 0);
signal RYROW: unsigned(8 downto 0);
signal CYROW: unsigned(8 downto 0);
signal SUM_RXCOL: unsigned(7 downto 0);
signal SUM_RYROW: unsigned(8 downto 0);
signal SUM_NXCOL: unsigned(7 downto 0);
signal SUM_NYROW: unsigned(8 downto 0);
signal MUX_NXCOL: unsigned(7 downto 0);
signal MUX_NYROW: unsigned(8 downto 0);
signal MUX_RXCOL: unsigned(7 downto 0);
signal MUX_RYROW: unsigned(8 downto 0);
signal MUX_CYROW: unsigned(8 downto 0);

signal DRAW_CHAR: std_logic;
signal DONE_DRAW: std_logic;
signal FIN_LINEA: std_logic;
signal FIN_TEXTO: std_logic;

signal aux : unsigned(3 downto 0);


begin
	clk <= CLOCK_50;
	reset_l <= KEY(0);
	reset <= not(KEY(0));
	

	--ínstaciar los componentes

C1: LT24setup
port map(
		clk => clk,
      reset_l => reset_l,
      LT24_LCD_ON => LT24_LCD_ON,
      LT24_RESET_N => LT24_RESET_N,
      LT24_CS_N =>LT24_CS_N,
      LT24_RS => LT24_RS,
      LT24_WR_N => LT24_WR_N,
      LT24_RD_N => LT24_RD_N,
      LT24_D => LT24_D,
		
      LT24_CS_N_Int => cs_n,
      LT24_RS_Int => rs,
      LT24_WR_N_Int => wr_n,
      LT24_RD_N_Int => '1',
      LT24_D_Int => std_logic_vector(d),
      LT24_Init_Done => init_done
		);

--yr <= ("0" & pos);		
--npix <= ("0000000000" & unsigned(sw(9 downto 3)));

		
C2: LCD_ctrl
port map(
		clk => clk, 
		reset => reset,
		LCD_init_Done => init_done, 
		OP_SETCURSOR => set_cur, 
		OP_DRAWCOLOR => draw_col,
		XCOL => xc,
		YROW => yr,
		RGB => rgb,
		NUM_PIX => npix,
		LCD_CS_N => cs_n, 
		LCD_WR_N => wr_n, 
		LCD_RS => rs,
		LCD_DATA => d,
		DONE_CURSOR => done_cur, 
		DONE_COLOUR => done_col
);

c3: LCD_drawing
port map(
	clk => clk, 
	reset => reset,
   DEL_SCREEN => not KEY(1), 
	DRAW_FIG => DRAW_CHAR,
	COLOUR_CODE => col_code,
	DONE_CURSOR => done_cur,
	DONE_COLOUR => done_col,
	RXCOL => RXCOL,
	RYROW => RYROW,
	DONE_DRAW => DONE_DRAW,
	OP_SETCURSOR => set_cur, 
	OP_DRAWCOLOR => draw_col,
	XCOL => xc,
	YROW => yr,
   RGB => rgb,
	NUM_PIX => npix
);

c4: LCD_uart
port map(
	clk => clk, 
	reset => reset,
   UART_TX => UART_RX,
	CHAR_CODE => code,
	new_data => new_data
);

c5: rom_chars
port map(
	clk      => clk,
   addr     => std_logic_vector(CMEM),
   datout   => ROM_data
);

-- proceso sincrono que actualiza el estado en flanco de reloj. Reset asincrono.
    process (clk,reset)
      begin
        if reset='1' then epres<=e0;
          elsif clk'event and clk='1' then epres<=esig;
        end if;
    end process;

-- proceso combinacional que determina el valor de esig (estado siguiente)
    process (epres, new_data, FIN_CONT, FIN_CMEM)
    begin
        case epres is 
            -- una clausula when por cada estado posible
			when e0 => esig <= e1;
			--when e1 => esig <= e11;
			when e1 => esig <= e2;
            when e2 => if new_data = '1'  then esig <= e3;
            			else esig <= e2;
            			end if;
            when e3 => esig <= e4;
            when e4 => esig <= e5;
			when e5 => esig <= e6;
            when e6 => if FIN_CONT = '1' and FIN_CMEM = '1'then esig <= e8;
							elsif FIN_CONT = '1' and FIN_CMEM = '0' then esig <= e7;
							elsif FIN_CONT = '0' and ROM_data_aux = '1' then esig <= e10;
							else esig <= e6;
            			end if;
			when e7 => esig <= e6;
			when e8 => if FIN_LINEA = '0' then esig <= e9;
							else esig <= e11;
							end if;
			when e9 => esig <= e1;
			when e10 => if DONE_DRAW = '1' then esig <= e6;
						else esig <= e10;
						end if;
			when e11 => esig <= e1; 
        end case;
    end process;
    
    --Señales de control
    
--	SEL_INIX <= '1' when epres = e0 or (epres = e9 and FIN_LINEA = '1')else '0';
--	SEL_INIY <= '1' when epres = e0 or (epres = e9 and FIN_LINEA = '0' and FIN_TEXTO = '0') else '0';
	SEL_INIX <= '1' when epres = e0  or epres = e11 else '0';
	SEL_INIY <= '1' when epres = e0  else '0'; 
--	SEL_CYROW <= '1' when epres = e0 else '0';
--	LD_CYROW <= '1' when epres = e0 or (epres = e9 and FIN_LINEA = '1') else '0';
	LD_NXCOL <= '1' when epres = e0 or epres = e9 or epres = e11 else '0'; 
	LD_NYROW <= '1' when epres = e0 or epres = e11 else '0'; 
	
	SEL_NXCOL <= '1' when epres = e1 or epres = e7 else '0';
	SEL_NYROW <= '1' when epres = e1 or (epres = e9 and FIN_LINEA = '0') else '0'; 
	LD_RXCOL <= '1' when (epres = e1 or (epres = e6 and FIN_CONT = '0') or epres = e8 or epres = e7) else '0'; 
	LD_RYROW <= '1' when (epres = e1 or (epres = e6 and FIN_CONT = '1' and FIN_CMEM = '0')) else '0';
	
	LD_ADDR <= '1' when epres = e3 else '0';
 	LD_CONT <= '1' when epres = e5 or epres = e7 else '0';
 	LD_CMEM <= '1' when epres = e4 else '0';
 	INC_CONT <= '1' when epres = e6 and FIN_CONT = '0' else '0';
 	INC_CMEM <= '1' when (epres = e6 and FIN_CONT = '1' and FIN_CMEM = '0') else '0';
	DONE <= '1' when epres = e9 else '0';
	
	DRAW_CHAR <= '1' when (epres = e6 and FIN_CONT = '0' and ROM_data_aux = '1') else '0';
	
 	
 	----------------------------------------
    ------ UNIDAD DE PROCESO ---------------
    ----------------------------------------
    
    -- codigo apropiado para cada uno de los componentes de la UP
    --  --Contadores
    process (clk, reset) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
	    if (LD_CONT = '1') then CONT<="000";
	    elsif (INC_CONT='1') then CONT<=CONT+1;
    	    end if;
          end if;
      end process;



      --FIN_CONT <= '1' when CONT = 3 else '0';
	  -- Aumentamos el limite a 4 para ver si asi cuenta el ultimo bit.
	  -- Testear para ver posibles problemas.
      FIN_CONT <= '1' when CONT = 4 else '0';
    
    
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
	    if (LD_CMEM='1') then CMEM<=RADDR;
	    elsif (INC_CMEM='1') then CMEM<=CMEM+1;
    	    end if;
          end if;
      end process;
		MAX_CMEM <= RADDR + "0000000000000100";
      FIN_CMEM <= '1' when CMEM = MAX_CMEM else '0';
    
    -- Registro de velocidad
    process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_ADDR='1') then RADDR<=ADDR;
    	    end if;
          end if;
    end process;


	------------------------------------------------------------------
	-- Gestion de dibujo.
	------------------------------------------------------------------

	-- REGISTROS
			
	process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_NXCOL='1') then NXCOL<=MUX_NXCOL;
    	    end if;
          end if;
    end process;

	process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_NYROW='1') then NYROW<=MUX_NYROW;
    	    end if;
          end if;
    end process;

	process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_RXCOL='1') then RXCOL<=MUX_RXCOL;
    	    end if;
          end if;
    end process;

	process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_RYROW='1') then RYROW<=MUX_RYROW;
    	    end if;
          end if;
    end process;
	 
	 process (clk) -- si tiene señales asincronas, hay que incluirlas en la lista
        begin
    	if clk'event and clk='1' then 
    	    if (LD_CYROW='1') then CYROW<=MUX_CYROW;
    	    end if;
          end if;
    end process;

	 
	 FIN_LINEA <= '1' when SUM_NXCOL > 210 else '0';
	 FIN_TEXTO <= '1' when SUM_NYROW > 300 else '0';
	 
	-- MULTIPLEXORES

	MUX_NXCOL <= x"00" when SEL_INIX = '1' else SUM_NXCOL;
	MUX_NYROW <= "0" & x"00" when SEL_INIY = '1' else SUM_NYROW;
	--MUX_NYROW <= CYROW when SEL_INIY = '1' else SUM_NYROW;

	MUX_RXCOL <= NXCOL when SEL_NXCOL = '1' else SUM_RXCOL;
	MUX_RYROW <= NYROW when SEL_NYROW = '1' else SUM_RYROW;

	MUX_CYROW <= NYROW when SEL_CYROW = '1' else "0" & x"00";
	-- SUMADORES
	SUM_RXCOL <= RXCOL + 5; 
	SUM_RYROW <= RYROW + 5;
	
	SUM_NXCOL <= NXCOL + 25; 
	SUM_NYROW <= NYROW + 30;

	ADDR <= (code - 97) * 5;

	col_code <= unsigned(SW(2 downto 0));

--a <= unsigned(ROM_data);
   aux <= unsigned(ROM_data);
	ROM_data_aux <= aux(to_integer(cont));

--FIN_MEM <= FIN_CMEM;

--b <= aux(to_integer(cont));
b <= FIN_LINEA;
--DF <= DRAW_FIG;
--SUMx <= SUM_RXCOL;
--SUMy <= SUM_RYROW;

end rtl;