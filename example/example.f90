program main
    use, intrinsic :: iso_fortran_env
    use :: mod_is_positive
    use :: mod_mean
    implicit none

    block
        print *, all([is_positive(-1_int8), &
                      is_positive(-1_int16), &
                      is_positive(-1_int32), &
                      is_positive(-1_int64), &
                      is_positive(-1.0_real32), &
                      is_positive(-1.0_real64)])

        print *, all([is_positive(1_int8), &
                      is_positive(1_int16), &
                      is_positive(1_int32), &
                      is_positive(1_int64), &
                      is_positive(1.0_real32), &
                      is_positive(1.0_real64)])
    end block

    block
        real(real64) :: x5(1, 1, 1, 1, 1)
        real(real64) :: x10(1, 1, 1, 1, 1, &
                            1, 1, 1, 1, 1)
        real(real64) :: x15(1, 1, 1, 1, 1, &
                            1, 1, 1, 1, 1, &
                            1, 1, 1, 1, 1)
        x5 = 5d0
        x10 = 10d0
        x15 = 15d0
        print *, mean(x5), mean(x10), mean(x15)
    end block
end program main
