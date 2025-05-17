library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity decode is
    port (
        instruction : in  STD_LOGIC_VECTOR (31 downto 0);
        clock       : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        RegDst      : in  STD_LOGIC;
        RegWrite    : in  STD_LOGIC;
        MemToReg    : in  STD_LOGIC;
        memory_data : in  STD_LOGIC_VECTOR (31 downto 0);
        alu_result  : in  STD_LOGIC_VECTOR (31 downto 0);
        register_rs : out STD_LOGIC_VECTOR (31 downto 0);
        register_rt : out STD_LOGIC_VECTOR (31 downto 0);
        immediate   : out STD_LOGIC_VECTOR (31 downto 0);
        jump_addr   : out STD_LOGIC_VECTOR (31 downto 0)
    );
end decode;

architecture Behavioral of decode is
    type reg_array is array(0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal RegFile : reg_array := (
        X"00000000", -- Register 0 (ZERO)
        X"11111111", -- Register 1
        X"22222222", -- Register 2
        X"33333333", -- Register 3
        X"44444444", -- Register 4
        others => X"01010101"
    );

begin

    -- Register Write Process (Synchronous)
    reg_writer: process(clock, reset)
        variable write_index : integer;
        variable write_value : STD_LOGIC_VECTOR(31 downto 0);
        variable temp_reg : reg_array;
    begin
        if reset = '1' then
            temp_reg := (
                X"00000000", -- Register 0 (ZERO)
                X"11111111", -- Register 1
                X"22222222", -- Register 2
                X"33333333", -- Register 3
                X"44444444", -- Register 4
                others => X"01010101"
            );
            RegFile <= temp_reg;
        elsif rising_edge(clock) then
            temp_reg := RegFile; -- Copy current state

            if RegWrite = '1' then
                -- Determine destination register
                if RegDst = '0' then
                    write_index := to_integer(unsigned(instruction(20 downto 16)));
                else
                    write_index := to_integer(unsigned(instruction(15 downto 11)));
                end if;

                -- Prevent write to register 0
                if write_index /= 0 then
                    -- Select data source
                    if MemToReg = '1' then
                        write_value := memory_data;
                    else
                        write_value := alu_result;
                    end if;

                    temp_reg(write_index) := write_value;
                end if;
            end if;

            RegFile <= temp_reg; -- Update registers
        end if;
    end process;

    -- Register Read and Immediate Decode (Combinational)
    reg_read: process(instruction, RegFile)
        variable rs_addr, rt_addr : integer;
        variable imm : STD_LOGIC_VECTOR(31 downto 0);
    begin
        -- Read register addresses
        rs_addr := to_integer(unsigned(instruction(25 downto 21)));
        rt_addr := to_integer(unsigned(instruction(20 downto 16)));

        -- Assign register outputs
        register_rs <= RegFile(rs_addr);
        register_rt <= RegFile(rt_addr);

        -- Sign-extend immediate
        imm(15 downto 0) := instruction(15 downto 0);
        imm(31 downto 16) := (others => instruction(15));
        immediate <= imm;

        -- Compute jump address (shift left by 6 bits)
        jump_addr <= "000000" & instruction(25 downto 0);
    end process;

end Behavioral;