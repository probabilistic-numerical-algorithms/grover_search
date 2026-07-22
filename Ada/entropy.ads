pragma ada_2022;

generic
  type real is digits <>;
package entropy is

  type entropy_seed is mod 2 ** 64;

  protected type safe_seed is
    procedure set (seed : entropy_seed);
    function get return entropy_seed;
    procedure update;
  private
    value : entropy_seed := 0;
  end safe_seed;

  global_seed : safe_seed;

  function uniform_real return real
    with post => (0.0 <= uniform_real'result
                  and uniform_real'result < 1.0);

end entropy;
