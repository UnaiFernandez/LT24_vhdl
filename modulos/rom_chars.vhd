library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 
use work.mirom_pkg.all;

entity rom_chars is
  port (
    clk		: in  std_logic;
    addr	: in  std_logic_vector(15 downto 0);
    datout	: out std_logic_vector(3 downto 0)
  );
end entity rom_chars;

architecture a of rom_chars is
--   type rom_type is array (0 to (2**7)-1) of std_logic_vector(16 downto 0);
   signal rom : rom_type := mirom;
   signal read_addr : std_logic_vector(15 downto 0);
begin
  process(clk) is
  begin
    if (clk'event and clk='1') then
      read_addr <= addr;
    end if;
  end process;

  datout <= rom(to_integer(unsigned(read_addr)));

end architecture a;