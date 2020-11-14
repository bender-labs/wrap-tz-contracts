type bps = nat

type tokens_storage = {
  fees_contract : address,
  fees_ratio: bps,
  tokens : map(string, address),
  mints : big_map(string, unit)
};
