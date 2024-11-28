(assert_invalid
  (module
    (type $ht (handler))
    (tag $e (param i32))
    (func
      (suspend_to $ht $e (i32.const 42) (ref.null $ht)))
  )
  "type mismatch"
)
;; write test to check invalid handler type tag with suspend_to 
;; write test to check resume_with without a named handler cont
;; pipe binary output of ref interp (./wasm -d input_file -o output.wasm -> change output .wat...) into wasm-tools validate

(assert_invalid 
  (module 
    (tag $e)
    (type $ht (handler))
    (type $g (func (param)))
    (type $f (func (param (ref $ht))))
    (type $k (cont $f))
    
    (func $g (type $g) ;; no handler ref
        (suspend_to $ht $e)
      )
      
    (func (export "handled_wrong")
      (block $h (result (ref $k))
        (resume_with $k (on $e $h) (cont.new $k (ref.func $g))) ;; should fail type check!
        (unreachable)
      )
      (drop))) 
  "type mismatch")


(module
  (type $ht (handler))
  (type $ft (func (param (ref $ht))))
  (type $ct (cont $ft))

  (func $noop (type $ft))
  (elem declare func $noop)

  (func $make-cont (result (ref $ct))
     (cont.new $ct (ref.func $noop)))

  (func $f (export "f") (result i32)
     (call $make-cont)
     (ref.is_null))
)
(assert_return (invoke "f") (i32.const 0))


(module
  (tag $e)

  (type $ht (handler))
  (type $f (func (param (ref $ht))))
  (type $g (func (param)))
  (type $k (cont $f))
  (type $k2 (cont $g))

  (func $f (type $f)
    (suspend_to $ht $e (local.get 0))
    (drop) ;; drop named handler
  )

  (func (export "handled_proper")
    (block $h (result (ref $k))
      (resume_with $k (on $e $h) (cont.new $k (ref.func $f)))
      (unreachable)
    )
    (drop)
  ) 
  
  (elem declare func $f)
)
(assert_return (invoke "handled_proper"))

(module
  (type $ht (handler (i32 i64 f32 f64)))
  (type $ft (func (param (ref $ht))))
  (type $ct (cont $ft))

  (func $noop (type $ft))
  (elem declare func $noop)

  (func $make-cont (result (ref $ct))
     (cont.new $ct (ref.func $noop)))

  (func $f (export "f") (result i32)
     (call $make-cont)
     (ref.is_null))
)
(assert_return (invoke "f") (i32.const 0))


;; Summation example
(module
  (type $ht (handler))
  (type $ft (func (param (ref $ht))))
  (type $ct (cont $ft))

  (tag $yield (param i32))

  (func $nats (type $ft)
    (local $h (ref $ht))
    (local $i i32)
    (local.set $h (local.get 0))
    (loop $next
      (suspend_to $ht $yield
        (local.get $i) (local.get $h))
      (local.set $h)
      (local.set $i (i32.add (i32.const 1) (local.get $i)))
      (br $next)))

  (func (export "sumUp") (param $n i32) (result i32)
    (local $i i32)
    (local $j i32)
    (local $k (ref $ct))
    (local.set $k (cont.new $ct (ref.func $nats)))
    (loop $next
      (block $on_yield (result i32 (ref $ct))
        (resume_with $ct (on $yield $on_yield) (local.get $k))
        (return (local.get $i))
      ) ;; on_yield
      (local.set $k)
      (i32.add (local.get $i))
      (local.set $i)
      (local.set $j (i32.add (i32.const 1) (local.get $j)))
      (br_if $next (i32.le_u (local.get $j) (local.get $n)))
   )
   (return (local.get $i)))
   
   (elem declare func $nats)
)
(assert_return (invoke "sumUp" (i32.const 10)) (i32.const 55))
