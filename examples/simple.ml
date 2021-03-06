open Core.Std
open Async.Std
open Async_parallel.Std

let p s = Printf.printf "%s: %s\n%!" (Pid.to_string (Unix.getpid ())) s

let foo () =
  p "solving...";
  Clock.after (sec 1.) >>| fun () -> "bar"
;;

let main () =
  Parallel.run ~where:(`On "hkg-qws-r01") foo >>> function
  | Error e -> p (sprintf "died with exception %s" e)
  | Ok str ->
    p (sprintf "main process gets the result: %s" str);
    Shutdown.shutdown 0
;;

let () =
  Exn.handle_uncaught ~exit:true (fun () ->
    Parallel.init ~cluster:
      {Cluster.master_machine = Unix.gethostname ();
       worker_machines = ["hkg-qws-r01"; "hkg-qws-r02"]} ();
    p "calling main";
    main ();
    p "calling scheduler go";
    never_returns (Scheduler.go ()))
;;
