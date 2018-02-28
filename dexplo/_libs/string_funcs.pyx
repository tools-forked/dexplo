

# check for valid regex
# look up the except at end def double evaluate(self, double x) except *:
import numpy as np
from numpy import nan
from numpy cimport ndarray, uint8_t
from libc.string cimport strcat
import re

cimport cython
cimport numpy as np

DTYPE = np.int8
ctypedef np.int8_t DTYPE_t


def capitalize(ndarray[object] arr):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        if arr[i] is not None:
            result[i] = arr[i].capitalize()
        else:
            result[i] = None
    return result

def capitalize_2d(ndarray[object, ndim=2] arr):
    cdef int i, j
    cdef int nr = arr.shape[0]
    cdef int nc = arr.shape[1]
    cdef ndarray[object, ndim=2] result = np.empty((nr, nc), dtype='object')
    for i in range(nr):
        for j in range(nc):
            if arr[i, j] is not None:
                result[i, j] = arr[i, j].capitalize()
            else:
                arr[i, j] = None
    return result

def center(ndarray[object] arr, int width, str fill_character=' '):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        if arr[i] is not None:
            result[i] = arr[i].center(width, fill_character)
        else:
            result[i] = None
    return result

def center_2d(ndarray[object, ndim=2] arr, int width, str fill_character=' '):
    cdef int i, j
    cdef int nr = len(arr)
    cdef int nc = arr.shape[1]
    cdef ndarray[object, ndim=2] result = np.empty((nr, nc), dtype='object')
    for i in range(nr):
        for j in range(nc):
            if arr[i, j] is not None:
                result[i, j] = arr[i, j].center(width, fill_character)
            else:
                result[i, j] = None
    return result

def contains(ndarray[object] arr, str pat, case=True, flags=0, na=nan, regex=True):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[DTYPE_t, ndim=1] result = np.empty(n, dtype=DTYPE)
    if regex:
        if case == False:
            flags = flags | re.IGNORE_CASE
        pattern = re.compile(pat, flags=flags)
        for i in range(n):
            result[i] = bool(pattern.search(arr[i]))
    else:
        if case:
            for i in range(n):
                result[i] = pat in arr[i]
        else:
            pat = pat.lower()
            for i in range(n):
                result[i] = pat in arr[i].lower()
    return result.view(dtype=np.bool)

def count(ndarray[object] arr, str pattern):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[np.int64_t, ndim=1] result = np.empty(n, dtype=np.int64)
    
    meta_chars = r'^[^.()\\$*^?{}\[\]|]+$'
    if re.match(meta_chars, pattern) is not None:
        for i in range(n):
            result[i] = arr[i].count(pattern)
        return result
    else:
        pat = re.compile(pattern)
        for i in range(n):
            result[i] = len(pat.findall(arr[i]))
        return result

def decode(ndarray[object] arr, str encoding, str errors='strict'):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        try:
            result[i] = bytes.decode(arr[i], encoding, errors)
        except TypeError:
            result[i] = nan
    return result

def encode(ndarray[object] arr, str encoding, str errors='strict'):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        result[i] = arr[i].encode(encoding, errors)
    return result

def endswith(ndarray[object] arr, str pat, na=nan):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[DTYPE_t] result = np.empty(n, dtype=DTYPE)
    for i in range(n):
        result[i] = arr[i].endswith(pat)
    return result

def find(ndarray[object] arr, str sub, int start=0, end=None):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[int] result = np.empty(n, dtype=int)
    for i in range(n):
        result[i] = arr[i].find(sub, start, end)
    return result

def get(ndarray[object] arr, int i):
    cdef int j
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for j in range(n):
        try:
            result[j] = arr[j][i]
        except IndexError:
            result[j] = nan
    return result

def get_dummies(ndarray[object] arr, sep='|'):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')


def lower(ndarray[object] arr):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        result[i] = arr[i].lower()
    return result

def title(ndarray[object] arr):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        result[i] = arr[i].title()
    return result

def upper(ndarray[object] arr):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='object')
    for i in range(n):
        result[i] = arr[i].upper()
    return result
