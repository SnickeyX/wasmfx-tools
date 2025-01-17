;; temporary testing file 
(module
  (tag $e (param i32))

  (type $ht (handler))
  (type $f (func (param (ref $ht))))
  (type $g (func (param)))
  (type $k (cont $f))
  (type $k2 (cont $g))
  
  (func $g (type $g))

  (func $f (type $f)
    (suspend_to $ht $e (i32.const 1) (local.get 0))
    (drop) ;; drop named handler
  )

  (func (export "handled_proper")
    (block $h (result i32 (ref $k2))
      (resume_with $k2 (on $e $h) (cont.new $k2 (ref.func $g)))
      (unreachable)
    )
    (drop)
    (drop)
  ) 
  
  (elem declare func $f $g)
)
(assert_return (invoke "handled_proper"))