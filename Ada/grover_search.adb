--  Grover's Resonant Search Algorithm Package Body
--  Language: Ada 2022
--  Direct Contact Action Epistemic State Vector Search

pragma ada_2022;

with ada.numerics.generic_elementary_functions;
with interfaces;
with ada.calendar;
with entropy;

package body grover_search is

   package real_math is
           new ada.numerics.generic_elementary_functions (real);
   use real_math;

   package real_entropy is new entropy (real);
   use real_entropy;

   ----------------
   -- Initialize --
   ----------------

   procedure initialize (amplitudes : in out amplitude_array) is
      n          : constant real := real (amplitudes'length);
      init_value : constant real := 1.0 / sqrt (n);
   begin
      --  Initialize state vector with uniform prior (maximum entropy)
      parallel for i in amplitudes'range loop
         amplitudes (i) := init_value;
      end loop;
   end initialize;

   -------------------
   -- Sum_Recursive --
   -------------------

   function Sum_Recursive (Amplitudes : Amplitude_Array) return Real
     with
       Pre  => Amplitudes'Length > 0,
       Post => (if Amplitudes'Length = 1 then
            Sum_Recursive'Result = Amplitudes (Amplitudes'First))
   is
      Result : Real := 0.0;
   begin
      if Amplitudes'Length = 1 then
         Result := Amplitudes (Amplitudes'First);
      elsif Amplitudes'Length > 1 then
         declare
            Mid   : constant Integer := Amplitudes'First + (Amplitudes'Length / 2) - 1;
            Left  : Real;
            Right : Real;
         begin
            parallel do
               Left  := Sum_Recursive (Amplitudes (Amplitudes'First .. Mid));
            and
               Right := Sum_Recursive (Amplitudes (Mid + 1 .. Amplitudes'Last));
            end do;
            Result := Left + Right;
         end;
      end if;
      return Result;
   end Sum_Recursive;

   ----------------------
   -- Sum_Sq_Recursive --
   ----------------------

   function Sum_Sq_Recursive (Amplitudes : Amplitude_Array) return Real
     with
       Pre  => Amplitudes'Length > 0,
       Post => (if Amplitudes'Length = 1 then
            Sum_Sq_Recursive'Result =
                 Amplitudes (Amplitudes'First) * Amplitudes (Amplitudes'First))
   is
      Result : Real := 0.0;
   begin
      if Amplitudes'Length = 1 then
         Result := Amplitudes (Amplitudes'First) * Amplitudes (Amplitudes'First);
      elsif Amplitudes'Length > 1 then
         declare
            Mid   : constant Integer := Amplitudes'First + (Amplitudes'Length / 2) - 1;
            Left  : Real;
            Right : Real;
         begin
            parallel do
               Left  := Sum_Sq_Recursive (Amplitudes (Amplitudes'First .. Mid));
            and
               Right := Sum_Sq_Recursive (Amplitudes (Mid + 1 .. Amplitudes'Last));
            end do;
            Result := Left + Right;
         end;
      end if;
      return Result;
   end Sum_Sq_Recursive;

   ---------------------
   -- Apply_predicate --
   ---------------------

   procedure apply_predicate (amplitudes : in out amplitude_array) is
   begin
      --  Evaluate the predicate for each slot
      for i in amplitudes'range loop
         if predicate (i) then
            amplitudes (i) := -amplitudes (i);
         end if;
      end loop;
   end apply_predicate;

   ---------------------
   -- Apply_diffusion --
   ---------------------

   procedure apply_diffusion (amplitudes : in out amplitude_array) is
      sum  : real;
      mean : real;
   begin
      --  Compute the spatial average (mean amplitude) using parallel tree reduction
      sum := Sum_Recursive (amplitudes);
      
      mean := sum / real (amplitudes'length);

      --  Apply the parallel reflection about the mean: 2 * Mean - A_i
      parallel for i in amplitudes'range loop
         amplitudes (i) := (2.0 * mean) - amplitudes (i);
      end loop;
   end apply_diffusion;

   ------------
   -- Search --
   ------------

   function search
     (n            : positive;
      iterations   : positive;
      perturbation : real) return natural
   is
      amplitudes : amplitude_array (0 .. n - 1);
      attempts   : positive := 1;
      max_attempts : constant positive := 20;
      
      r_val : real;
      sum_sq : real;
      factor : real;
      
      measured_idx : natural := 0;
      found : boolean := false;
      result_idx : natural := 0;
      
      use Ada.Calendar;
      use type Interfaces.Unsigned_64;
      T : Time := Clock;
      State : Interfaces.Unsigned_64 :=
      	    Interfaces.Unsigned_64 (Float (Seconds (T)) * 1000.0) +
	    Interfaces.Unsigned_64 (Interfaces.Unsigned_64(n) mod
	    			    Interfaces.Unsigned_64 (4294967296));
   begin
      
      while not found and attempts <= max_attempts loop
         --  1. Set initial amplitudes: 1.0 / sqrt(N)
         initialize (amplitudes);
         
         --  2. Add high-entropy perturbations if this is a retry and perturbation > 0.0
         if attempts > 1 and perturbation > 0.0 then
            for i in amplitudes'range loop
               amplitudes (i) := amplitudes (i) + 
                 (uniform_real - 0.5) * perturbation;
            end loop;
            
            --  Normalize after perturbation using parallel tree reduction
            sum_sq := Sum_Sq_Recursive (amplitudes);
            if sum_sq > 0.0 then
               factor := 1.0 / sqrt (sum_sq);
               for i in amplitudes'range loop
                  amplitudes (i) := amplitudes (i) * factor;
               end loop;
            end if;
         end if;
         
         --  3. Run the Grover iterations
         for step in 1 .. iterations loop
            apply_predicate (amplitudes);
            apply_diffusion (amplitudes);
         end loop;
         
         --  4. Measure probabilistically
         r_val := uniform_real;
         
         --  Compute total sum of squares for safe normalization using parallel tree reduction
         sum_sq := Sum_Sq_Recursive (amplitudes);
         
         declare
            cumulative : real := 0.0;
            prob : real;
            i : natural := amplitudes'first;
            done : boolean := false;
         begin
            measured_idx := amplitudes'first;
            while i <= amplitudes'last and not done loop
               prob := (amplitudes (i) * amplitudes (i)) / sum_sq;
               cumulative := cumulative + prob;
               measured_idx := i;
               if r_val <= cumulative then
                  done := true;
               else
                  i := i + 1;
               end if;
            end loop;
            
            --  Check if the measured index satisfies the predicate
            if predicate (measured_idx) then
               found := true;
               result_idx := measured_idx;
            end if;
         end;
         
         --  If measurement fails, we retry with perturbation
         attempts := attempts + 1;
      end loop;
      
      return result_idx;
   end search;

end grover_search;
