--
-- A thread-safe linear congruential (and thus predictable)
-- entropy generator.
--

pragma ada_2022;

package body entropy is

  protected body safe_seed is

    procedure set (seed : entropy_seed) is
    begin
      value := seed;
    end set;

    function get return entropy_seed is
    begin
      return value;
    end get;

    procedure update is

      -- The multiplier lcg_a comes from Steele, Guy; Vigna,
      -- Sebastiano (28 September 2021). ‘Computationally easy,
      -- spectrally good multipliers for congruential
      -- pseudorandom number generators’.
      -- arXiv:2001.05304v3 [cs.DS]

      lcg_a : constant entropy_seed := 16#F1357AEA2E62A9C5#;

      -- The value of lcg_c is not critical, but should be odd.
      -- A number taken from https://oeis.org/A000111 for no good
      -- reason.

      lcg_c : constant entropy_seed := 19391512145;

    begin
      value := (lcg_a * value) + lcg_c;
    end update;

  end safe_seed;

  function uniform_real return real is
    -- Take the high 48 bits of the seed and divide by 2**48.
    retval : constant real :=
                 real (global_seed.get / (2**16)) / real (2**48);
  begin
    global_seed.update;
    return retval;
  end uniform_real;

end entropy;
