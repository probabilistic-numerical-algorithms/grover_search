pragma ada_2022;

package Grover_Fixed_Types is

   type Index_Type is mod 2**20; 

   type Data_Array is array (Index_Type) of Integer;
   type Fixed_Amplitude_Array is array (Index_Type) of Integer;
   
   pragma Pack (Data_Array);
   pragma Pack (Fixed_Amplitude_Array);

   -- Create an explicit heap-pointer type for the amplitude array
   type Amplitude_Pointer is access all Fixed_Amplitude_Array;

end Grover_Fixed_Types;
