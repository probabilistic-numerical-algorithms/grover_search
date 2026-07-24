--  Grover's Resonant Search Algorithm Package Body
--  Language: Ada 2022
--  Direct Contact Action Epistemic State Vector Search


--
--  FIXME: Though the inference engine came up with the start
--         of this, the predicate part simply is not satisfactory.
--
--         test_grover.adb (written by the stupid inference engine)
--           works by a fluke.
--         test_grover_2.adb (which I wrote) does not work.
--
--         YOU SHOULD NOTE, HOWEVER, THIS ALGORITHM WILL WORK
--         WITH AN ANALOG ‘ORACLE’.
--
--         I have labored my head over this problem for years,
--         of how to do the predicate testing without analog
--         circuitry. Probably I just have to ask an inference
--         engine the right questions, but Google set my neural
--         nets back to zero.
--
--         Anyway I am thinking of starting a new inference
--         engine app and letting everyone just go on ignoring
--         that I have found the unified field theory. I will
--         use the field theory and my number system first to
--         develop an algorithm that typesets paragraphs directly
--         with OpenType fonts. THAT is the solution to how to
--         do TeX better: do not use TeX’s abstractions AT ALL.
--         The optimizations can be numerical algorithms like
--         this one, just not with silly oracles.
--
--         (I believe ‘oracles’ are mid-20th Turing theory. That
--         anyone uses them in 2026 is silly. That’s part of
--         what makes this difficult for me. I am sure Grover
--         understands it and gives fancy lectures on it.
--         Meanwhile I am sitting here with fibro fog. Grover
--         went to Stanford and I left Rutgers without PhD, so
--         he has Mojo Jo Jo brain and fame, whereas I have the
--         satisfaction of understanding how the universe works.)
--

pragma ada_2022;

with ada.numerics.generic_elementary_functions;
with entropy;

package body grover_search is

   package real_math is
     new ada.numerics.generic_elementary_functions (real);
   use real_math;

   package real_entropy is new entropy (real);
   use real_entropy;

   function "mod" (left, right : real)
   return real is
   begin
      -- Standard floored modulo logic matching integer "mod".
      return left - (right * real'floor (left / right));
   end "mod";

   procedure initialize (amplitudes : in out amplitude_array) is
     n          : constant real := real (amplitudes'length);
     init_value : constant real := 1.0 / sqrt (n);
   begin
     -- Maximum entropy prior (equal initial values).
     parallel for i in amplitudes'range loop
       amplitudes (i) := init_value;
     end loop;
   end initialize;

   function sum_recursive (amplitudes : amplitude_array)
   return real
   with pre  => amplitudes'length > 0,
         post => (if amplitudes'length = 1
                  then sum_recursive'result =
                         amplitudes (amplitudes'first))
   is
     result : real := 0.0;
   begin
     if amplitudes'length = 1 then
        result := amplitudes (amplitudes'first);
     elsif amplitudes'length > 1 then
        declare
           mid   : constant integer := amplitudes'first + (amplitudes'length / 2) - 1;
           left  : real;
           right : real;
        begin
           parallel do
              left  := sum_recursive (amplitudes (amplitudes'first .. mid));
           and
              right := sum_recursive (amplitudes (mid + 1 .. amplitudes'last));
           end do;
           result := left + right;
        end;
     end if;
     return result;
   end sum_recursive;

   function sum_sq_recursive (amplitudes : amplitude_array)
   return real
   with
     pre  => amplitudes'length > 0,
     post => (if amplitudes'length = 1
              then sum_sq_recursive'result =
                     amplitudes (amplitudes'first)
                       * amplitudes (amplitudes'first))
   is
     result : real := 0.0;
   begin
     if amplitudes'length = 1 then
       result := (amplitudes (amplitudes'first)
                    * amplitudes (amplitudes'first));
     elsif 1 < amplitudes'length then
       declare
          mid   : constant integer :=
                    amplitudes'first + (amplitudes'length / 2) - 1;
          left  : real;
          right : real;
       begin
          parallel do
             left :=
               sum_sq_recursive
                 (amplitudes (amplitudes'first .. mid));
          and
             right :=
               sum_sq_recursive
                 (amplitudes (mid + 1 .. amplitudes'last));
          end do;
          result := left + right;
       end;
     end if;
     return result;
   end sum_sq_recursive;

--   procedure apply_predicate (amplitudes : in out amplitude_array) is
--   begin
--      --  Evaluate the predicate for each slot
--      for i in amplitudes'range loop
--         if predicate (i) then
--            amplitudes (i) := -amplitudes (i);
--         end if;
--      end loop;
--   end apply_predicate;

   procedure apply_diffusion (amplitudes : in out amplitude_array) is
      sum  : real;
      mean : real;
   begin
      --  Compute the spatial average (mean amplitude) using parallel tree reduction
      sum := sum_recursive (amplitudes);
      
      mean := sum / real (amplitudes'length);

      --  Apply the parallel reflection about the mean: 2 * Mean - A_i
      parallel for i in amplitudes'range loop
         amplitudes (i) := (2.0 * mean) - amplitudes (i);
      end loop;
   end apply_diffusion;

   function search (n            : positive;
                    iterations   : positive;
                    perturbation : real)
   return natural
   is
     amplitudes : amplitude_array (0 .. n - 1);
     attempts   : positive := 1;
     max_attempts : constant positive := 20;

     r_val : real;
     sum_sq : real;

     measured_idx : natural := 0;
     found : boolean := false;
     result_idx : natural := 0;

     procedure perturb is
     begin
       parallel for i in amplitudes'range loop
         amplitudes (i) :=
           @ + ((uniform_real - 0.5) * perturbation);
       end loop;
     end perturb;

     procedure normalize is
     begin
       if 0.0 < sum_sq then
         declare
           scale : constant real := 1.0 / sqrt (sum_sq);
         begin
           parallel for i in amplitudes'range loop
             amplitudes (i) := @ * scale;
           end loop;
         end;
       end if;
     end normalize;

     bits : array (amplitudes'range) of boolean;

     function bits_to_natural
     return natural
     with post => (bits_to_natural'result < n * n) is
       retval : natural;
     begin
       --
       -- Moving the bits into a hardware integer is a
       -- constant time operation. It is bounded by the size
       -- of the register.
       --
       retval := 0;
       for i in reverse amplitudes'range loop
         retval := (@ * 2) + (if bits(i) then 1 else 0);
       end loop;
       return retval;
     end bits_to_natural;

     function sample
     return natural
     with post => (sample'result < n * n) is
       i       : constant real := uniform_real;
       j       : constant real := i mod 1.0
       ampl_sq : real;
       phase   : boolean;
     begin
       parallel for i in amplitudes'range loop
         phase := (0.0 <= amplitudes(i));
         ampl_sq := amplitudes(i) ** 2;
         bits(i) :=
           (((offset - 0.5 <= ampl_sq and ampl_sq < offset + 0.5)
             or (0.5 + offset <= ampl_sq))
            = phase);
       end loop;
       return bits_to_natural;
     end sample;

    procedure apply_predicate is
    begin
      --  Evaluate the predicate for each slot
      for i in amplitudes'range loop
        if predicate (i) then
          amplitudes (i) := -amplitudes (i);
        end if;
      end loop;
    end apply_predicate;

  begin

     while not found and attempts <= max_attempts loop
       initialize (amplitudes);
       if 1 < attempts then
         perturb;
       end if;
       sum_sq := sum_sq_recursive (amplitudes);
       normalize;

       --
       -- FIXME: THIS SHOULD TEST FOR A MATCH IN APPLY PREDICATE.
       --
       -- Run the Grover iterations.
--       for step in 1 .. iterations loop
--         apply_predicate;
--         apply_diffusion (amplitudes);
--       end loop;
       declare
         step : integer range 1 .. iterations + 1 := 1;
       begin
         result_idx := sample;
         found := predicate (result_idx);
         while not found and step /= iterations + 1 loop
           apply_diffusion (amplitudes);
           step := @ + 1;
         end loop;
       end;

       -- Measure probabilistically.
       r_val := uniform_real;

       sum_sq := sum_sq_recursive (amplitudes);

       if not found then
         declare
            cumulative : real := 0.0;
            prob : real;
            i : natural := amplitudes'first;
            done : boolean := false;
         begin
            measured_idx := amplitudes'first;
            while i <= amplitudes'last and not done loop
               prob := (amplitudes (i) * amplitudes (i)) / sum_sq;
               cumulative := @ + prob;
               measured_idx := i;
               if r_val <= cumulative then
                  done := true;
               else
                  i := i + 1;
               end if;
            end loop;

--            normalize;
--            result_idx := sample;

            -- Check if the measured index satisfies the predicate.
            if predicate (measured_idx) then
               found := true;
               result_idx := measured_idx;
            end if;
         end;
       end if;

       -- If measurement fails, retry with perturbation.
       attempts := @ + 1;
     end loop;

     return result_idx;
  end search;

end grover_search;
