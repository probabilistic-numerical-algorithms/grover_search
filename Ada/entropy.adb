--
-- A thread-safe linear congruential (and thus predictable)
-- entropy generator.
--

pragma ada_2022;

package body entropy is

  protected body safe_seed is

    procedure set (seed : in entropy_seed) is
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
      -- This number is (to within orders of magnitude) the
      -- Boltzmann constant, which is the means (at the time of
      -- this writing) by which the Système international d’unités
      -- defines the Kelvin in terms of the Joule.

      lcg_c : constant entropy_seed := 1380649;

    begin
      set ((lcg_a * get) + lcg_c);
    end update;

  end safe_seed;

  function uniform_real (least    : in real := 0.0;
                         greatest : in real := real'pred (1.0))
  return real is
    -- Take the high 48 bits of the seed and divide by 2**48.
    r      : real;
    retval : real;
  begin
    global_seed.update;
    r := real (global_seed.get / (2**16)) / real (2**48);
    retval := ((real (1.0) - r) * least) + (r * greatest);
    if retval < least then
      retval := least;
    elsif greatest < retval then
      retval := greatest;
    end if;
    return retval;
  end uniform_real;

  function uniform_integer (least    : in integer;
                            greatest : in integer)
  return integer is
    u : constant real := uniform_real;
    r : constant real := real (greatest - least + 1) * u;
  begin
    return least + integer (real'floor (r));
  end uniform_integer;

end entropy;
