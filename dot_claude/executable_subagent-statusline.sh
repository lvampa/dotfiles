#!/bin/bash
# Subagent status line: name model · description · elapsed · tokens
# Adds the resolved model to each running subagent's row. Rows whose
# model isn't resolved yet are left with the default rendering.

input=$(cat)

echo "$input" | jq -c '
  def shortmodel:
    if . == null then null else
      (sub("^claude-"; "") | sub("-[0-9]{8}$"; "")) as $s
      | ($s | capture("^(?<fam>[a-z]+)-(?<rest>.+)$")?) as $c
      | if $c == null then $s
        else ($c.fam[0:1] | ascii_upcase) + $c.fam[1:] + " " + ($c.rest | gsub("-"; "."))
        end
    end;

  def fmtelapsed:
    if . == null then null else
      ((now - (if . > 10000000000 then ./1000 else . end)) | floor) as $s
      | if $s < 60 then "\($s)s"
        else "\($s / 60 | floor)m\($s % 60)s"
        end
    end;

  def fmttokens:
    if . == null then null else
      if . >= 1000 then "\((. / 100 | round) / 10)k" else "\(.)" end
    end;

  "[2m" as $dim | "[0m" as $reset
  | "[38;5;74m" as $aegean
  | "[38;5;173m" as $terracotta
  | "[38;5;180m" as $sand
  | .tasks[]
  | select(.model != null)
  | {
      id: .id,
      content: (
        (.label // .name // .type)
        + $dim + " · " + $reset + $aegean + (.model | shortmodel) + $reset
        + (if .description then $dim + " · " + $reset + .description else "" end)
        + $dim + " · " + $reset + $terracotta + (.startTime | fmtelapsed) + $reset
        + (if .tokenCount then $dim + " · " + $reset + $sand + "↓" + (.tokenCount | fmttokens) + $reset else "" end)
      )
    }
'
