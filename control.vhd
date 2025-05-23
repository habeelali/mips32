library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control is
    port (
        instruction : in  STD_LOGIC_VECTOR(31 downto 0);
        reset        : in  STD_LOGIC;
        RegDst       : out STD_LOGIC;
        ALUSrc       : out STD_LOGIC;
        MemToReg     : out STD_LOGIC;
        RegWrite     : out STD_LOGIC;
        MemRead      : out STD_LOGIC;
        MemWrite     : out STD_LOGIC;
        Branch       : out STD_LOGIC;
        ALUOp        : out STD_LOGIC_VECTOR(1 downto 0);
        Jump         : out STD_LOGIC
    );
end control;

architecture Behavioral of control is
    signal opcode : STD_LOGIC_VECTOR(5 downto 0);
begin
    process (instruction, reset)
    begin
        opcode <= instruction(31 downto 26);
        
        if reset = '1' then
            RegDst   <= '0'; ALUSrc   <= '0';
            MemToReg <= '0'; RegWrite <= '0';
            MemRead  <= '0'; MemWrite <= '0';
            Branch   <= '0'; ALUOp    <= "00";
            Jump     <= '0';
        else
            case opcode is
                -- R-format (add, sub, etc.)
                when "000000" =>
                    RegDst   <= '1'; ALUSrc   <= '0';
                    MemToReg <= '0'; RegWrite <= '1';
                    MemRead  <= '0'; MemWrite <= '0';
                    Branch   <= '0'; ALUOp    <= "10";
                    Jump     <= '0';
                -- lw (load word)
                when "100011" =>
                    RegDst   <= '0'; ALUSrc   <= '1';
                    MemToReg <= '1'; RegWrite <= '1';
                    MemRead  <= '1'; MemWrite <= '0';
                    Branch   <= '0'; ALUOp    <= "00";
                    Jump     <= '0';
                -- sw (store word)
                when "101011" =>
                    RegDst   <= 'X'; ALUSrc   <= '1';
                    MemToReg <= 'X'; RegWrite <= '0';
                    MemRead  <= '0'; MemWrite <= '1';
                    Branch   <= '0'; ALUOp    <= "00";
                    Jump     <= '0';
                -- beq (branch equal)
                when "000100" =>
                    RegDst   <= 'X'; ALUSrc   <= '0';
                    MemToReg <= 'X'; RegWrite <= '0';
                    MemRead  <= '0'; MemWrite <= '0';
                    Branch   <= '1'; ALUOp    <= "01";
                    Jump     <= '0';
                -- jmp (jump)
                when "000010" =>
                    RegDst   <= 'X'; ALUSrc   <= 'X';
                    MemToReg <= 'X'; RegWrite <= '0';
                    MemRead  <= '0'; MemWrite <= '0';
                    Branch   <= '0'; ALUOp    <= "XX";
                    Jump     <= '1';
                -- Default case
                when others =>
                    RegDst   <= '0'; ALUSrc   <= '0';
                    MemToReg <= '0'; RegWrite <= '0';
                    MemRead  <= '0'; MemWrite <= '0';
                    Branch   <= '0'; ALUOp    <= "00";
                    Jump     <= '0';
            end case;
        end if;
    end process;
end Behavioral;