library IEEE;
use IEEE.STD_LOGIC_1164.all;

package mirom_pkg is
    type rom_type is array (0 to 129) of std_logic_vector(3 downto 0);
    constant mirom : rom_type;
end mirom_pkg;

package body mirom_pkg is
    constant mirom : rom_type := (
        x"6", x"9", x"9", x"F", x"9",         -- A
        x"7", x"9", x"7", x"9", x"7",         -- B
        x"E", x"1", x"1", x"1", x"E",			 -- c
        x"3", x"5", x"9", x"5", x"3",			 -- D
		  x"F", x"1", x"F", x"1", x"F",         -- E
        x"F", x"1", x"F", x"1", x"1",         -- F
        x"F", x"1", x"D", x"9", x"F",			 -- G
        x"9", x"9", x"F", x"9", x"9",			 -- H
		  x"7", x"2", x"2", x"2", x"7",         -- I
        x"F", x"4", x"4", x"4", x"3",         -- J
        x"9", x"5", x"3", x"5", x"9",			 -- K
		  x"1", x"1", x"1", x"1", x"F",			 -- L
        x"9", x"B", x"F", x"D", x"9",			 -- N
		  x"9", x"F", x"F", x"9", x"9",         -- M
        x"6", x"9", x"9", x"9", x"6",         -- O
        x"7", x"9", x"7", x"1", x"1",			 -- P
        x"6", x"9", x"9", x"D", x"E",			 -- Q
		  x"7", x"9", x"7", x"5", x"9",         -- R
        x"F", x"1", x"F", x"8", x"F",         -- S
        x"7", x"2", x"2", x"2", x"2",			 -- T
        x"9", x"9", x"9", x"9", x"6",			 -- U 
		  x"9", x"9", x"5", x"3", x"1",         -- V
        x"0", x"0", x"0", x"0", x"8",         -- .
		  x"9", x"9", x"6", x"9", x"9",         -- X
        x"9", x"9", x"F", x"8", x"7",			 -- Y
        x"F", x"8", x"6", x"1", x"F"			 -- Z
    );
end package body mirom_pkg;