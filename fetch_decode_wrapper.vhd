library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fetch_decode_wrapper is
    port (
        -- Global signals
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        
        -- Control signals (manually set for testing)
        RegDst     : in  STD_LOGIC;  -- From control logic
        RegWrite   : in  STD_LOGIC;  -- From control logic
        MemToReg   : in  STD_LOGIC;  -- From control logic
        br_dec     : in  STD_LOGIC;  -- Branch decision (e.g., for beq)
        jmp_dec    : in  STD_LOGIC;  -- Jump decision
        
        -- ALU/Memory inputs (for testing)
        alu_result : in  STD_LOGIC_VECTOR(31 downto 0); -- From ALU
        memory_data: in  STD_LOGIC_VECTOR(31 downto 0); -- From memory
        
        -- Outputs to verify
        pc_out     : out STD_LOGIC_VECTOR(31 downto 0); -- From fetch
        instr      : out STD_LOGIC_VECTOR(31 downto 0); -- From fetch
        register_rs: out STD_LOGIC_VECTOR(31 downto 0); -- From decode
        register_rt: out STD_LOGIC_VECTOR(31 downto 0); -- From decode
        immediate  : out STD_LOGIC_VECTOR(31 downto 0); -- From decode
        jump_addr  : out STD_LOGIC_VECTOR(31 downto 0)  -- From decode
    );
end fetch_decode_wrapper;

architecture Behavioral of fetch_decode_wrapper is

    -- Internal signals for connecting fetch and decode
    signal br_addr_sig : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal jump_addr_sig : STD_LOGIC_VECTOR(31 downto 0);
    signal instr_sig : STD_LOGIC_VECTOR(31 downto 0); -- Internal signal for instruction

    -- Instantiate modules
    component fetch
        port (
            pc_out    : out STD_LOGIC_VECTOR(31 downto 0);
            instr     : out STD_LOGIC_VECTOR(31 downto 0);
            br_addr   : in  STD_LOGIC_VECTOR(31 downto 0);
            jmp_addr  : in  STD_LOGIC_VECTOR(31 downto 0);
            br_dec    : in  STD_LOGIC;
            jmp_dec   : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            clk       : in  STD_LOGIC
        );
    end component;

    component decode
        port (
            instruction : in  STD_LOGIC_VECTOR(31 downto 0);
            clock       : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            RegDst      : in  STD_LOGIC;
            RegWrite    : in  STD_LOGIC;
            MemToReg    : in  STD_LOGIC;
            memory_data : in  STD_LOGIC_VECTOR(31 downto 0);
            alu_result  : in  STD_LOGIC_VECTOR(31 downto 0);
            register_rs : out STD_LOGIC_VECTOR(31 downto 0);
            register_rt : out STD_LOGIC_VECTOR(31 downto 0);
            immediate   : out STD_LOGIC_VECTOR(31 downto 0);
            jump_addr   : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin

    -- Map fetch module
    u_fetch: fetch
    port map (
        pc_out    => pc_out,
        instr     => instr_sig,    -- Connect to internal signal
        br_addr   => br_addr_sig,
        jmp_addr  => jump_addr_sig,
        br_dec    => br_dec,
        jmp_dec   => jmp_dec,
        rst       => reset,
        clk       => clk
    );

    -- Map decode module
    u_decode: decode
    port map (
        instruction => instr_sig,  -- Use internal signal here
        clock       => clk,
        reset       => reset,
        RegDst      => RegDst,
        RegWrite    => RegWrite,
        MemToReg    => MemToReg,
        memory_data => memory_data,
        alu_result  => alu_result,
        register_rs => register_rs,
        register_rt => register_rt,
        immediate   => immediate,
        jump_addr   => jump_addr_sig
    );

    -- Forward signals to outputs
    instr <= instr_sig;       -- Output instruction to wrapper port
    jump_addr <= jump_addr_sig;

end Behavioral;