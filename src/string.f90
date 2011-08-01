module string

  use global
  use error, only: warning

  implicit none

  interface int_to_str
     module procedure int4_to_str, int8_to_str
  end interface

contains

!===============================================================================
! SPLIT_STRING takes a sentence and splits it into separate words much like the
! Python string.split() method.
!
! Arguments:
!   string = input line
!   words  = array of words
!   n      = total number of words
!===============================================================================

  subroutine split_string(string, words, n)

    character(*), intent(in)  :: string
    character(*), intent(out) :: words(max_words)
    integer,      intent(out) :: n

    character(1)  :: char    ! current character
    integer       :: i       ! current index
    integer       :: i_start ! starting index of word
    integer       :: i_end   ! ending index of word
    character(max_line_len) :: msg

    i_start = 0
    i_end = 0
    n = 0
    do i = 1, len_trim(string)
       char = string(i:i)

       ! Note that ACHAR(9) is a horizontal tab
       if ((i_start == 0) .and. (char /= ' ') .and. (char /= achar(9))) then
          i_start = i
       end if
       if (i_start > 0) then
          if ((char == ' ') .or. (char == achar(9))) i_end = i - 1
          if (i == len_trim(string))   i_end = i
          if (i_end > 0) then
             n = n + 1
             if (i_end - i_start + 1 > len(words(n))) then
                msg = "The word '" // string(i_start:i_end) // "' is longer than " &
                     & // "the space allocated for it."
                call warning(msg)
             end if
             words(n) = string(i_start:i_end)
             ! reset indices
             i_start = 0
             i_end = 0
          end if
       end if
    end do

  end subroutine split_string

!===============================================================================
! SPLIT_STRING_WL takes a string that includes logical expressions for a list of
! bounding surfaces in a cell and splits it into separate words. The characters
! (, ), :, and # count as separate words since they represent operators.
!
! Arguments:
!   string  = input line
!   words   = array of words
!   n       = number of words
!===============================================================================

  subroutine split_string_wl(string, words, n)

    character(*), intent(in)  :: string
    character(*), intent(out) :: words(max_words)
    integer,      intent(out) :: n

    character(1)  :: char    ! current character
    integer       :: i       ! current index
    integer       :: i_start ! starting index of word
    integer       :: i_end   ! ending index of word

    i_start = 0
    i_end = 0
    n = 0
    do i = 1, len_trim(string)
       char = string(i:i)

       ! Check for special characters
       if (index('():#', char) > 0) then
          if (i_start > 0) then
             i_end = i - 1
             n = n + 1
             words(n) = string(i_start:i_end)
          end if
          n = n + 1
          words(n) = char
          i_start = 0
          i_end = 0
          cycle
       end if

       if ((i_start == 0) .and. (char /= ' ')) then
          i_start = i
       end if
       if (i_start > 0) then
          if (char == ' ')           i_end = i - 1
          if (i == len_trim(string)) i_end = i
          if (i_end > 0) then
             n = n + 1
             words(n) = string(i_start:i_end)
             ! reset indices
             i_start = 0
             i_end = 0
          end if
       end if
    end do
  end subroutine split_string_wl

!===============================================================================
! CONCATENATE takes an array of words and concatenates them together in one
! string with a single space between words
!
! Arguments:
!   words   = array of words
!   n_words = total number of words
!   string  = concatenated string
!===============================================================================

  function concatenate(words, n_words) result(string)

    character(*),   intent(in)  :: words(n_words)
    integer,        intent(in)  :: n_words
    character(max_line_len)     :: string

    integer :: i ! index

    string = words(1)
    if (n_words == 1) return
    do i = 2, n_words
       string = trim(string) // ' ' // words(i)
    end do

  end function concatenate

!===============================================================================
! LOWER_CASE converts a string to all lower case characters
!===============================================================================

  elemental subroutine lower_case(word)

    character(*), intent(inout) :: word

    integer :: i
    integer :: ic

    do i = 1,len(word)
       ic = ichar(word(i:i))
       if (ic >= 65 .and. ic < 90) word(i:i) = char(ic+32)
    end do

  end subroutine lower_case

!===============================================================================
! UPPER_CASE converts a string to all upper case characters
!===============================================================================

  elemental subroutine upper_case(word)

    character(*), intent(inout) :: word

    integer :: i
    integer :: ic

    do i = 1,len(word)
       ic = ichar(word(i:i))
       if (ic >= 97 .and. ic < 122) word(i:i) = char(ic-32)
    end do

  end subroutine upper_case

!===============================================================================
! IS_NUMBER determines whether a string of characters is all 0-9 characters
!===============================================================================

  function is_number(word) result(number)

    character(*), intent(in) :: word
    logical                  :: number

    integer :: i
    integer :: ic

    number = .true.
    do i = 1, len_trim(word)
       ic = ichar(word(i:i))
       if (ic < 48 .or. ic >= 58) number = .false.
    end do
    
  end function is_number

!===============================================================================
! INT4_TO_STR converts an integer(4) to a string.
!===============================================================================

  function int4_to_str(num) result(str)

    integer, intent(in) :: num
    character(11) :: str

    write (str, '(I11)') num
    str = adjustl(str)

  end function int4_to_str

!===============================================================================
! INT8_TO_STR converts an integer(8) to a string.
!===============================================================================

  function int8_to_str(num) result(str)

    integer(8), intent(in) :: num
    character(21) :: str

    write (str, '(I21)') num
    str = adjustl(str)

  end function int8_to_str

!===============================================================================
! STR_TO_INT converts a string to an integer. 
!===============================================================================

  function str_to_int(str) result(num)

    character(*), intent(in) :: str
    integer(8) :: num
    
    character(5) :: fmt
    integer      :: w
    integer      :: ioError

    ! Determine width of string
    w = len_trim(str)
    
    ! Create format specifier for reading string
    write(UNIT=fmt, FMT='("(I",I2,")")') w

    ! read string into integer
    read(UNIT=str, FMT=fmt, IOSTAT=ioError) num
    if (ioError > 0) num = ERROR_INT

  end function str_to_int

!===============================================================================
! STR_TO_REAL converts an arbitrary string to a real(8). Generally this function
! is intended for strings for which the exact format is not known. If the format
! of the number is known a priori, the appropriate format descriptor should be
! used in lieu of this routine because of the extra overhead.
!
! Arguments:
!   string = character(*) containing number to convert
!===============================================================================

  function str_to_real(string) result(num)

    character(*), intent(in) :: string
    real(8) :: num

    integer :: index_decimal  ! index of decimal point
    integer :: index_exponent ! index of exponent character
    integer :: w              ! total field width
    integer :: d              ! number of digits to right of decimal point
    integer :: ioError

    character(8)            :: fmt ! format for reading string
    character(max_line_len) :: msg ! error message

    ! Determine total field width
    w = len_trim(string)

    ! Determine number of digits to right of decimal point
    index_decimal = index(string, '.')
    index_exponent = max(index(string, 'd'), index(string, 'D'), &
         & index(string, 'e'), index(string, 'E'))
    if (index_decimal > 0) then
       if (index_exponent > 0) then
          d = index_exponent - index_decimal - 1
       else
          d = w - index_decimal
       end if
    else
       d = 0
    end if

    ! Create format specifier for reading string
    write(fmt, '("(E",I2,".",I2,")")') w, d

    ! Read string
    read(UNIT=string, FMT=fmt, IOSTAT=ioError) num
    if (ioError > 0) num = ERROR_REAL

  end function str_to_real

!===============================================================================
! REAL_TO_STR converts a real(8) to a string based on how large the value is and
! how many significant digits are desired. By default, six significants digits
! are used.
!===============================================================================

  function real_to_str(num, sig_digits) result(string)

    real(8),           intent(in) :: num        ! number to convert
    integer, optional, intent(in) :: sig_digits ! # of significant digits
    character(15)                 :: string     ! string returned

    integer      :: decimal ! number of places after decimal
    integer      :: width   ! total field width
    real(8)      :: num2    ! absolute value of number 
    character(9) :: fmt     ! format specifier for writing number

    ! set default field width
    width = 15

    ! set number of places after decimal
    if (present(sig_digits)) then
       decimal = sig_digits
    else
       decimal = 6
    end if

    ! Create format specifier for writing character
    num2 = abs(num)
    if (num2 == ZERO) then
       write(fmt, '("(F",I2,".",I2,")")') width, 1
    elseif (num2 < 1.0e-1_8) then
       write(fmt, '("(ES",I2,".",I2,")")') width, decimal - 1
    elseif (num2 >= 1.0e-1_8 .and. num2 < 1.0_8) then
       write(fmt, '("(F",I2,".",I2,")")') width, decimal
    elseif (num2 >= 1.0_8 .and. num2 < 10.0_8) then
       write(fmt, '("(F",I2,".",I2,")")') width, max(decimal-1, 0)
    elseif (num2 >= 10.0_8 .and. num2 < 100.0_8) then
       write(fmt, '("(F",I2,".",I2,")")') width, max(decimal-2, 0)
    elseif (num2 >= 100.0_8 .and. num2 < 1000.0_8) then
       write(fmt, '("(F",I2,".",I2,")")') width, max(decimal-3, 0)
    elseif (num2 >= 100.0_8 .and. num2 < 10000.0_8) then
       write(fmt, '("(F",I2,".",I2,")")') width, max(decimal-4, 0)
    elseif (num2 >= 10000.0_8 .and. num2 < 100000.0_8) then
       write(fmt, '("(F",I2,".",I2,")")') width, max(decimal-5, 0)
    else
       write(fmt, '("(ES",I2,".",I2,")")') width, decimal - 1
    end if

    ! Write string and left adjust
    write(string, fmt) num
    string = adjustl(string)

  end function real_to_str

end module string
