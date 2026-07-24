pragma ada_2022;

with Grover_Fixed_Types; use Grover_Fixed_Types;
with Ada.Real_Time;

package Grover_Fixed_Processor is

   procedure Initialize_Amplitudes (Amplitudes : out Fixed_Amplitude_Array);

   procedure Parallel_Oracle_Zen5 (
      Data       : in     Data_Array;
      Target     : in     Integer;
      Amplitudes : in out Fixed_Amplitude_Array);

   procedure Parallel_Diffusion_Zen5 (
      Amplitudes  : in out Fixed_Amplitude_Array;
      Match_Found :    out Boolean;
      Peak_Index  :    out Index_Type);

   procedure Find_Peak (
      Amplitudes  : in     Fixed_Amplitude_Array;
      Peak_Index  :    out Index_Type);

--   procedure Execute_Search_Benchmark (
--      Data          : in     Data_Array;
--      Target        : in     Integer;
--      Found_Index   :    out Index_Type;
--      Success       :    out Boolean;
--      Elapsed_Time  :    out Ada.Real_Time.Time_Span);

end Grover_Fixed_Processor;
