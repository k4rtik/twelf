(* MTP Strategy: Version 1.3 *)
(* Author: Carsten Schuermann *)

functor MTPStrategy (structure MTPGlobal : MTPGLOBAL
		     structure StateSyn' : STATESYN
		     structure MTPFilling : MTPFILLING
		       sharing MTPFilling.StateSyn = StateSyn'
		     structure MTPSplitting : MTPSPLITTING
	  	       sharing MTPSplitting.StateSyn = StateSyn'
		     structure MTPRecursion : MTPRECURSION
		       sharing MTPRecursion.StateSyn = StateSyn'
		     structure MTPrint : MTPRINT
		       sharing MTPrint.StateSyn = StateSyn'
		     structure Timers : TIMERS) 
  : MTPSTRATEGY =
struct

  structure StateSyn = StateSyn'

  local

    structure S = StateSyn

    fun printInit () = 
        if !Global.chatter > 3 then print "Strategy\n"
	else ()

    fun printFilling () = 
        if !Global.chatter > 5 then print ("[Filling ... ")
	else if !Global.chatter> 4 then print ("F")
	     else  ()

    fun printRecursion () = 
        if !Global.chatter > 5 then print ("[Recursion ...")
	else if !Global.chatter> 4 then print ("R")
	     else ()

    fun printSplitting () = 
        if !Global.chatter > 5 then print ("[Splitting ...")
	else if !Global.chatter> 4 then print ("S")
	     else ()

    fun printCloseBracket () = 
        if !Global.chatter > 5 then print ("]\n")
	else ()

    fun printQed () = 
        if !Global.chatter > 3 then print ("[QED]\n")
	else ()

    (* findMin L = Sopt

       Invariant:

       If   L be a set of splitting operators
       then Sopt = NONE if L = []
       else Sopt = SOME S, s.t. index S is minimal among all elements in L
    *)
    fun findMin nil = NONE
      | findMin (O :: L) =
	  let 
	    fun findMin' (nil, k, result) = result
	      | findMin' (O' :: L', k ,result)=
		  let 
		    val k' = MTPSplitting.index O' 
		  in
		    if MTPSplitting.applicable O' andalso 
		      MTPSplitting.index O' < k then findMin' (L', k', SOME O')
		    else findMin' (L', k, result)
		  end
	  in
	    findMin' (L, MTPSplitting.index O, SOME O)
	  end

    (* split   (givenStates, (openStates, solvedStates)) = (openStates', solvedStates')
       recurse (givenStates, (openStates, solvedStates)) = (openStates', solvedStates')
       fill    (givenStates, (openStates, solvedStates)) = (openStates', solvedStates')

       Invariant:
       openStates' extends openStates and
	 contains the states resulting from givenStates which cannot be 
	 solved using Filling, Recursion, and Splitting
       solvedStates' extends solvedStates and 
	 contains the states resulting from givenStates which can be 
	 solved using Filling, Recursion, and Splitting
    *)
    fun split (S :: givenStates, os as (openStates, solvedStates)) =
	case findMin ((Timers.time Timers.splitting MTPSplitting.expand) S) of 
	  NONE => fill (givenStates, (S :: openStates, solvedStates))
	| SOME splitOp =>
	    let 
	      val _ = printSplitting ()
	      val SL = (Timers.time Timers.splitting MTPSplitting.apply) splitOp
	      val _ = printCloseBracket ()
	      val SL' = map (fn S => MTPRecursion.apply (MTPRecursion.expand S)) SL
	    in
	      fill (SL' @ givenStates, os)
	    end

    and fill (nil, os) = os
      | fill (S :: givenStates, os as (openStates, solvedStates)) =
        case (Timers.time Timers.recursion MTPFilling.expand) S
	  of fillingOp =>
	     let
	       val _ = printFilling ()
	       val qed = (Timers.time Timers.recursion MTPFilling.apply) fillingOp
	       val _ = printCloseBracket ()
	     in
	       if qed then  fill (givenStates, os)
	       else split (S :: givenStates, os)
	     end

    (* run givenStates = (openStates', solvedStates')

       Invariant:
       openStates' contains the states resulting from givenStates which cannot be 
	 solved using Filling, Recursion, and Splitting
       solvedStates' contains the states resulting from givenStates which can be 
	 solved using Filling, Recursion, and Splitting
     *)       
    fun run givenStates = 
        let
	  val _ = printInit ()
	  val os = fill (givenStates, (nil, nil))
	  val _ = case os
	            of (nil, _) => printQed ()
		     | _ => ()
	in
	  os
	end

  in
    val run = run
  end (* local *)
end;  (* functor StrategyFRS *)

