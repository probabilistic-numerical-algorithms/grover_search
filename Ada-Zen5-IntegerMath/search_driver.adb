pragma ada_2022;

with System.Machine_Code;
with Grover_Fixed_Types;     use Grover_Fixed_Types;
with Grover_Fixed_Processor; use Grover_Fixed_Processor;
with Interfaces;             use Interfaces;
with Ada.Text_IO;            use Ada.Text_IO;
with Ada.Real_Time;          use Ada.Real_Time;
with Entropy;

procedure Search_Driver is

   package long_float_entropy is new entropy (long_float);
   use long_float_entropy;
   
   type Target_Guesses is range 1 .. 5;
   
   function Get_Loop_Count (Pass : Target_Guesses) return Integer is
   begin
      case Pass is
         when 1 => return 804;  -- M = 1
         when 2 => return 568;  -- M = 2
         when 3 => return 402;  -- M = 4
         when 4 => return 284;  -- M = 8
         when 5 => return 201;  -- M = 16
      end case;
   end Get_Loop_Count;

   Data         : Data_Array;
   Found_Index  : Index_Type;
   Target_Val   : Integer := 4242; -- Target marker
   Success      : Boolean := False;
   Amplitudes   : Fixed_Amplitude_Array;
   Current_Loop : Integer;
   
   Start_Cycles : Unsigned_64;
   End_Cycles   : Unsigned_64;
   Total_Cycles : Unsigned_64;

   Start_Clock  : Time;
   End_Clock    : Time;
   Elapsed_Span : Time_Span;
   SI_Seconds   : Duration;

   function Read_CPU_Cycles return Unsigned_64;
   -- Inline assembler to pull the low and high 32-bit registers from RDTSC
   pragma Machine_Attribute (Read_CPU_Cycles, "inline_always");

   function Read_CPU_Cycles return Unsigned_64 is
      Low, High : Unsigned_32;
      Result    : Unsigned_64;
   begin
      System.Machine_Code.Asm
        (Template => "rdtsc",
         Outputs  => (Unsigned_32'Asm_Output ("=a", Low),   -- EAX register
                      Unsigned_32'Asm_Output ("=d", High)),  -- EDX register
         Volatile => True);

      Result := Shift_Left (Unsigned_64 (High), 32) or Unsigned_64 (Low);
      return Result;
   end Read_CPU_Cycles;

begin
   -- [Populate Data Array here and insert Target_Val at multiple indices]
   for i in index_type loop
      Data(i) := uniform_integer (0, 3999);
   end loop;
   Data(1000) := Target_Val;
   Data(2000) := Target_Val;
   Data(3000) := Target_Val;

   for Pass in Target_Guesses loop
      Initialize_Amplitudes (Amplitudes);
      Current_Loop := Get_Loop_Count (Pass);

      -- START TELEMETRY CLOCK
      Start_Cycles := Read_CPU_Cycles;
      Start_Clock := Clock;

      for Step in 1 .. Current_Loop loop
         Parallel_Oracle_Zen5 (Data, Target_Val, Amplitudes);
         Parallel_Diffusion_Zen5 (Amplitudes);
      end loop;

      -- STOP TELEMETRY CLOCK
      End_Cycles := Read_CPU_Cycles;
      Total_Cycles := End_Cycles - Start_Cycles;
      End_Clock := Clock;
      Elapsed_Span := End_Clock - Start_Clock;

      Find_Peak (Amplitudes, Found_Index);

      if Data(Found_Index) = Target_Val then
         Success := True;
         SI_Seconds := To_Duration (Elapsed_Span);
         Put_Line ("Array size: " & Integer'Image (Index_Type'Range_Length));
         Put_Line ("Match locked at index: " & Index_Type'Image (Found_Index));
         Put_Line ("Pass iterations: " & Integer'Image (Current_Loop));
         Put_Line ("Hardware clock cycles consumed: " & Unsigned_64'Image (Total_Cycles));
         Put_Line ("Approximate time consumed: " & SI_Seconds'Image & " s");
         return;
      end if;
   end loop;
   
   if not Success then
      Put_Line ("Search bounds exhausted without convergence.");
   end if;
end Search_Driver;
