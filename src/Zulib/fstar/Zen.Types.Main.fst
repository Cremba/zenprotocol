module Zen.Types.Main

open Zen.Types.Extracted
open Zen.Types.Realized
open Zen.Cost
open Zen.Types.Data


val maxCost: nat
let maxCost = 200

type message =
    { cHash: hash;
      command: string;
      data: data }

noeq type costFunction =
    | CostFunc:
        #n:nat{n<=maxCost}
        -> f:(txSkeleton
              -> command:string
              -> data:data
              -> returnAddress:option lock
              -> #l:nat
              -> wallet l
              -> nat `cost` n)
        -> costFunction

noeq type mainFunction =
    | MainFunc:
        cf:costFunction
        -> mf:( txSkel:txSkeleton
                -> contractHash
                -> command:string
                -> data:data
                -> returnAddress:option lock
                -> #l:nat
                -> wallet:wallet l
                -> result (txSkeleton ** option message) `cost` force ((CostFunc?.f cf) txSkel command data returnAddress wallet)
              )
        -> mainFunction
