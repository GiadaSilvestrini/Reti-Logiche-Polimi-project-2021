library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
	port (
		i_clk : in std_logic;
		i_rst : in std_logic;
		i_start : in std_logic;
		i_data : in std_logic_vector(7 downto 0);
		o_address : out std_logic_vector(15 downto 0);
		o_done : out std_logic;
		o_en : out std_logic;
		o_we : out std_logic;
		o_data : out std_logic_vector (7 downto 0)
	);
end project_reti_logiche;

architecture progetto of project_reti_logiche is
	type state_type is (WaitStart, ReadMemory, Compute, WriteByteOne, WriteByteTwo, DoneAll, Restart);
	signal stato : state_type;
	signal num : std_logic_vector(7 downto 0);
	signal incount : SIGNED(15 downto 0);
	signal outcount : SIGNED(15 downto 0);	
	signal P1 : std_logic_vector (7 downto 0);
	signal P2 : std_logic_vector (7 downto 0);
	signal penultimo, ultimo: std_logic;
	begin
		process(i_clk, i_rst)
			begin
				if i_rst='1' then
					penultimo <= '0';
					ultimo <= '0';
					stato <= WaitStart;
					incount <= "0000000000000000";
					outcount <= "0000000000000000";
					P1 <= "00000000";
					P2 <= "00000000";
					o_address <= "0000000000000000";
					o_en <= '1';
					o_we <= '0';
					o_done <= '0';
				elsif i_clk'event and i_clk='0' then
					case stato is
						when WaitStart =>
							if i_start='1' then
								o_address <= std_logic_vector(incount);
								num <= i_data;
								stato <= ReadMemory;
							end if;
						when ReadMemory =>
							o_we <= '0';
							if std_logic_vector(incount) < num then
								o_address <= std_logic_vector(incount +1);
								stato <= Compute;
							else
								stato <= DoneAll;
							end if;
						when Compute =>
								P1(7) <= i_data(7) xor penultimo;
								P1(6) <= i_data(7) xor ultimo xor penultimo;
								P1(5) <= i_data(6) xor ultimo;
								P1(4) <= i_data(6) xor i_data(7) xor ultimo;
								P1(3) <= i_data(5) xor i_data(7);
								P1(2) <= i_data(5) xor i_data(6) xor i_data(7);
								P1(1) <= i_data(4) xor i_data(6);
								P1(0) <= i_data(4) xor i_data(5) xor i_data(6);
								P2(7) <= i_data(3) xor i_data(5);
								P2(6) <= i_data(3) xor i_data(4) xor i_data(5);
								P2(5) <= i_data(2) xor i_data(4);
								P2(4) <= i_data(2) xor i_data(3) xor i_data(4);
								P2(3) <= i_data(1) xor i_data(3);
								P2(2) <= i_data(1) xor i_data(2) xor i_data(3);
								P2(1) <= i_data(0) xor i_data(2);
								P2(0) <= i_data(0) xor i_data(1) xor i_data(2);
								penultimo <= i_data(1);
								ultimo <= i_data(0);
								stato <= WriteByteOne;
						when WriteByteOne =>
							o_we <= '1';
							o_address <= std_logic_vector(1000 + outcount);
							o_data <= P1;
							stato <= WriteByteTwo;
						when WriteByteTwo =>
							o_address <= std_logic_vector(1000 + outcount + 1);
							o_data <= P2;
							incount <= incount + 1;
							outcount <= outcount + 2;
							stato <= ReadMemory;
						when DoneAll =>
							o_done <= '1';
							penultimo <= '0';
							ultimo <= '0';
							incount <= "0000000000000000";
							outcount <= "0000000000000000";
							P1 <= "00000000";
							P2 <= "00000000";
							o_address <= "0000000000000000";
							o_en <= '1';
							o_we <= '0';
							stato <= Restart;
						when Restart =>
							if i_start <= '0' then
								o_done <= '0';
								stato <= WaitStart;
							end if;
					end case;	
				end if;
			end process;
	end progetto;