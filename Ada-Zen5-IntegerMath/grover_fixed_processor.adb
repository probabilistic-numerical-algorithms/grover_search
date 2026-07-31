pragma ada_2022;

with Ada.Unchecked_Deallocation;
with Ada.Real_Time; use Ada.Real_Time;
with Interfaces; use Interfaces;
with System.Machine_Code;

package body Grover_Fixed_Processor is

   Iterations : constant Integer := 804;

   function Read_CPU_Cycles return Unsigned_64;
   pragma Machine_Attribute (Read_CPU_Cycles, "inline_always");

   ---------------------------------------
   -- Native Assembly Cycle Counter Pass --
   ---------------------------------------
   function Read_CPU_Cycles return Unsigned_64 is
      Low, High : Unsigned_32;
      Result    : Unsigned_64;
   begin
      -- Executes the physical Time Stamp Counter read on Zen 5
      System.Machine_Code.Asm
        (Template => "rdtsc",
         Outputs  => (Unsigned_32'Asm_Output ("=a", Low),   -- EAX
                      Unsigned_32'Asm_Output ("=d", High)),  -- EDX
         Volatile => True);
         
      Result := Shift_Left (Unsigned_64 (High), 32) or Unsigned_64 (Low);
      return Result;
   end Read_CPU_Cycles;

   procedure Initialize_Amplitudes (Amplitudes : out Fixed_Amplitude_Array) is
      Uniform_Fixed_Phase : constant Integer := 64;
   begin
      parallel for I in Index_Type loop
         Amplitudes(I) := Uniform_Fixed_Phase;
      end loop;
   end Initialize_Amplitudes;

   -- Excerpt of the corrected package body
   procedure Parallel_Oracle_Zen5 (
      Data       : in     Data_Array;
      Target     : in     Integer;
      Amplitudes : in out Fixed_Amplitude_Array) 
   is
   begin
      -- The branchless match logic is computed directly inside the lane.
      -- This stops the experimental compiler from generating temporary stack vars.
      parallel for I in Index_Type loop
         Amplitudes(I) := Amplitudes(I) * (1 - 2 * Boolean'Pos (Data(I) = Target));
      end loop;
   end Parallel_Oracle_Zen5;

   procedure Parallel_Diffusion_Zen5 (
      Amplitudes  : in out Fixed_Amplitude_Array;
      Match_Found :    out Boolean;
      Peak_Index  :    out Index_Type) 
   is
      Sum_Total   : Long_Integer := 0;
      Mean        : Integer;
      N           : constant Long_Integer := 1_048_576;

      -- Thread-local trackers for the parallel loop block
      Local_Found : Boolean := False;
      Local_Idx   : Index_Type := 0;
   begin
      -- 1. Parallel reduction to compute the current mean
      parallel for I in Index_Type loop
         Sum_Total := @ + Long_Integer (Amplitudes(I));
      end loop;

      Mean := Integer (Sum_Total / N);

      -- 2. Combined reflection and inline numerical threshold scan
      parallel for I in Index_Type loop
         Amplitudes(I) := (2 * Mean) - Amplitudes(I);

         -- If any amplitude spikes past 256, resonance is locked.
         if Abs (Amplitudes(I)) > 256 then
            Local_Idx   := I;
            Local_Found := True;
         end if;
      end loop;

      -- 3. Return the flags back up to the driver loop
      Match_Found := Local_Found;
      Peak_Index  := Local_Idx;
   end Parallel_Diffusion_Zen5;

   procedure Find_Peak (
      Amplitudes  : in     Fixed_Amplitude_Array;
      Peak_Index  :    out Index_Type) 
   is
      Max_Val : Integer := -1;
   begin
      -- Run a clean, linear, single-threaded sweep over the data space.
      -- This guarantees zero thread collisions, zero race conditions,
      -- and leaves the system stack completely safe from s-intman panic.
      Peak_Index := 0;
      for I in Index_Type loop
         if Abs (Amplitudes(I)) > Max_Val then
            Max_Val    := Abs (Amplitudes(I));
            Peak_Index := I;
         end if;
      end loop;
   end Find_Peak;

end Grover_Fixed_Processor;
