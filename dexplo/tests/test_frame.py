import dexplo as dx
import numpy as np
from numpy import array, nan
import pytest
from dexplo.testing import assert_frame_equal, assert_array_equal, assert_dict_list


class TestFrameConstructorOneCol(object):

    def test_single_array_int(self):
        a = np.array([1, 2, 3])
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(a, df1._data['i'][:, 0])
        assert df1._column_info['a'].values == ('i', 0, 0)

    def test_single_array_float(self):
        a = np.array([1, 2.5, 3.2])
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(a, df1._data['f'][:, 0])
        assert df1._column_info['a'].values == ('f', 0, 0)

    def test_single_array_bool(self):
        a = np.array([True, False])
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(a.astype('int8'), df1._data['b'][:, 0])
        assert df1._column_info['a'].values == ('b', 0, 0)

    def test_single_array_string(self):
        a = np.array(['a', 'b'])
        df1 = dx.DataFrame({'a': a})
        a1 = array([1, 2], dtype='uint32')
        assert_array_equal(a1, df1._data['S'][:, 0])
        assert df1._column_info['a'].values == ('S', 0, 0)

    def test_single_array_dt(self):
        a = np.array([10, 20, 30], dtype='datetime64[ns]')
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(a, df1._data['M'][:, 0])
        assert df1._column_info['a'].values == ('M', 0, 0)

    def test_single_array_td(self):
        a = np.array([10, 20, 30], dtype='timedelta64[Y]')
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(a.astype('timedelta64[ns]'), df1._data['m'][:, 0])
        assert df1._column_info['a'].values == ('m', 0, 0)

    def test_single_list_int(self):
        a = np.array([1, 2, 3])
        df1 = dx.DataFrame({'a': a.tolist()})
        assert_array_equal(a, df1._data['i'][:, 0])
        assert df1._column_info['a'].values == ('i', 0, 0)

    def test_single_list_float(self):
        a = np.array([1, 2.5, 3.2])
        df1 = dx.DataFrame({'a': a.tolist()})
        assert_array_equal(a, df1._data['f'][:, 0])
        assert df1._column_info['a'].values == ('f', 0, 0)

    def test_single_list_bool(self):
        a = np.array([True, False])
        df1 = dx.DataFrame({'a': a.tolist()})
        assert_array_equal(a.astype('int8'), df1._data['b'][:, 0])
        assert df1._column_info['a'].values == ('b', 0, 0)

    def test_single_list_string(self):
        a = np.array(['a', 'b'])
        df1 = dx.DataFrame({'a': a.tolist()})
        a1 = array([1, 2], dtype='uint32')
        assert_array_equal(a1, df1._data['S'][:, 0])
        assert df1._column_info['a'].values == ('S', 0, 0)

    def test_single_list_dt(self):
        a = [np.datetime64(x, 'ns') for x in [10, 20, 30]]
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(np.array(a), df1._data['M'][:, 0])
        assert df1._column_info['a'].values == ('M', 0, 0)

    def test_single_list_td(self):
        a = [np.timedelta64(x, 'ns') for x in [10, 20, 30]]
        df1 = dx.DataFrame({'a': a})
        assert_array_equal(np.array(a), df1._data['m'][:, 0])
        assert df1._column_info['a'].values == ('m', 0, 0)


class TestFrameConstructorOneColArr(object):

    def test_single_array_int(self):
        a = np.array([1, 2, 3])
        df1 = dx.DataFrame(a)
        assert_array_equal(a, df1._data['i'][:, 0])
        assert df1._column_info['a0'].values == ('i', 0, 0)

    def test_single_array_float(self):
        a = np.array([1, 2.5, 3.2])
        df1 = dx.DataFrame(a)
        assert_array_equal(a, df1._data['f'][:, 0])
        assert df1._column_info['a0'].values == ('f', 0, 0)

    def test_single_array_bool(self):
        a = np.array([True, False])
        df1 = dx.DataFrame(a)
        assert_array_equal(a.astype('int8'), df1._data['b'][:, 0])
        assert df1._column_info['a0'].values == ('b', 0, 0)

    def test_single_array_string(self):
        a = np.array(['a', 'b'])
        df1 = dx.DataFrame(a)
        a1 = array([1, 2], dtype='uint32')
        assert_array_equal(a1, df1._data['S'][:, 0])
        assert df1._column_info['a0'].values == ('S', 0, 0)

    def test_single_array_dt(self):
        a = np.array([10, 20, 30], dtype='datetime64[ns]')
        df1 = dx.DataFrame(a)
        assert_array_equal(a, df1._data['M'][:, 0])
        assert df1._column_info['a0'].values == ('M', 0, 0)

    def test_single_array_td(self):
        a = np.array([10, 20, 30], dtype='timedelta64[Y]')
        df1 = dx.DataFrame(a)
        assert_array_equal(a.astype('timedelta64[ns]'), df1._data['m'][:, 0])
        assert df1._column_info['a0'].values == ('m', 0, 0)


class TestFrameConstructorMultipleCol(object):

    def test_array_int(self):
        a = np.array([1, 2, 3])
        b = np.array([10, 20, 30])
        arr = np.column_stack((a, b))
        df1 = dx.DataFrame({'a': a, 'b': b})
        assert_array_equal(arr, df1._data['i'])
        assert df1._column_info['a'].values == ('i', 0, 0)
        assert df1._column_info['b'].values == ('i', 1, 1)

    def test_array_float(self):
        a = np.array([1.1, 2, 3])
        b = np.array([10, 20.2, 30])
        arr = np.column_stack((a, b))
        df1 = dx.DataFrame({'a': a, 'b': b})
        assert_array_equal(arr, df1._data['f'])
        assert df1._column_info['a'].values == ('f', 0, 0)
        assert df1._column_info['b'].values == ('f', 1, 1)

    def test_array_bool(self):
        a = np.array([True, False, True])
        b = np.array([False, False, False])
        arr = np.column_stack((a, b)).astype('int8')
        df1 = dx.DataFrame({'a': a, 'b': b})
        assert_array_equal(arr, df1._data['b'])
        assert df1._column_info['a'].values == ('b', 0, 0)
        assert df1._column_info['b'].values == ('b', 1, 1)

    def test_array_string(self):
        a = np.array(['asdf', 'wer'])
        b = np.array(['wyw', 'xcvd'])
        df1 = dx.DataFrame({'a': a, 'b': b})
        a1 = array([[1, 1], [2, 2]], dtype='uint32')
        assert_array_equal(a1, df1._data['S'])
        assert df1._column_info['a'].values == ('S', 0, 0)
        assert df1._column_info['b'].values == ('S', 1, 1)

    def test_array_dt(self):
        a = np.array([10, 20, 30], dtype='datetime64[ns]')
        b = np.array([100, 200, 300], dtype='datetime64[ns]')
        arr = np.column_stack((a, b))
        df1 = dx.DataFrame({'a': a, 'b': b})
        assert_array_equal(arr, df1._data['M'])
        assert df1._column_info['a'].values == ('M', 0, 0)
        assert df1._column_info['b'].values == ('M', 1, 1)

    def test_array_td(self):
        a = np.array([10, 20, 30], dtype='timedelta64[Y]')
        b = np.array([1, 2, 3], dtype='timedelta64[Y]')
        arr = np.column_stack((a, b)).astype('timedelta64[ns]')
        df1 = dx.DataFrame({'a': a, 'b': b})
        assert_array_equal(arr, df1._data['m'])
        assert df1._column_info['a'].values == ('m', 0, 0)
        assert df1._column_info['b'].values == ('m', 1, 1)

    def test_array_int(self):
        a = np.array([1, 2])
        b = np.array([10, 20, 30])
        with pytest.raises(ValueError):
            dx.DataFrame({'a': a, 'b': b})


a = [1, 2, 5, 9, 3, 4, 5, 1]
b = [1.5, 8, 9, 1, 2, 3, 2, 8]
c = list('abcdefgh')
d = [True, False, True, False] * 2
e = [np.datetime64(x, 'D') for x in range(8)]
f = [np.timedelta64(x, 'D') for x in range(8)]
df_mix = dx.DataFrame({'a': a,
                       'b': b,
                       'c': c,
                       'd': d,
                       'e': e,
                       'f': f},
                      columns=list('abcdef'))


class TestAllDataTypesList:

    def test_all(self):
        assert_array_equal(np.array(a), df_mix._data['i'][:, 0])
        assert_array_equal(np.array(b), df_mix._data['f'][:, 0])
        a1 = array([1, 2, 3, 4, 5, 6, 7, 8], dtype='uint32')
        assert_array_equal(a1, df_mix._data['S'][:, 0])
        assert_array_equal(np.array(d).astype('int8'), df_mix._data['b'][:, 0])
        assert_array_equal(np.array(e, dtype='datetime64[ns]'), df_mix._data['M'][:, 0])
        assert_array_equal(np.array(f, dtype='timedelta64[ns]'), df_mix._data['m'][:, 0])

        assert df_mix._column_info['a'].values == ('i', 0, 0)
        assert df_mix._column_info['b'].values == ('f', 0, 1)
        assert df_mix._column_info['c'].values == ('S', 0, 2)
        assert df_mix._column_info['d'].values == ('b', 0, 3)
        assert df_mix._column_info['e'].values == ('M', 0, 4)
        assert df_mix._column_info['f'].values == ('m', 0, 5)


a1 = np.array([1, 2, 5, 9, 3, 4, 5, 1])
b1 = np.array([1.5, 8, 9, 1, 2, 3, 2, 8])
c1 = np.array(list('abcdefgh'), dtype='O')
d1 = np.array([True, False, True, False] * 2)
e1 = np.array(range(8), dtype='datetime64[D]')
f1 = np.array(range(8), dtype='timedelta64[D]')
df_mix1 = dx.DataFrame({'a': a,
                        'b': b,
                        'c': c,
                        'd': d,
                        'e': e,
                        'f': f},
                       columns=list('abcdef'))


class TestAllDataTypesArray:

    def test_all(self):
        assert_array_equal(a1, df_mix1._data['i'][:, 0])
        assert_array_equal(b1, df_mix1._data['f'][:, 0])
        arr1 = array([1, 2, 3, 4, 5, 6, 7, 8], dtype='uint32')
        assert_array_equal(arr1, df_mix1._data['S'][:, 0])
        assert_array_equal(d1.astype('int8'), df_mix1._data['b'][:, 0])
        assert_array_equal(e1, df_mix1._data['M'][:, 0])
        assert_array_equal(f1, df_mix1._data['m'][:, 0])

        assert df_mix1._column_info['a'].values == ('i', 0, 0)
        assert df_mix1._column_info['b'].values == ('f', 0, 1)
        assert df_mix1._column_info['c'].values == ('S', 0, 2)
        assert df_mix1._column_info['d'].values == ('b', 0, 3)
        assert df_mix1._column_info['e'].values == ('M', 0, 4)
        assert df_mix1._column_info['f'].values == ('m', 0, 5)


arr = np.column_stack((a1, b1, c1, d1, e1, f1))
df_mix2 = dx.DataFrame(arr)


class TestAllDataTypesObjectArray:

    def test_all(self):
        assert_array_equal(a1, df_mix2._data['i'][:, 0])
        assert_array_equal(b1, df_mix2._data['f'][:, 0])
        arr1 = array([1, 2, 3, 4, 5, 6, 7, 8], dtype='uint32')
        assert_array_equal(arr1, df_mix2._data['S'][:, 0])
        assert_array_equal(d1.astype('int8'), df_mix2._data['b'][:, 0])
        assert_array_equal(e1, df_mix2._data['M'][:, 0])
        assert_array_equal(f1, df_mix2._data['m'][:, 0])

        assert df_mix2._column_info['a0'].values == ('i', 0, 0)
        assert df_mix2._column_info['a1'].values == ('f', 0, 1)
        assert df_mix2._column_info['a2'].values == ('S', 0, 2)
        assert df_mix2._column_info['a3'].values == ('b', 0, 3)
        assert df_mix2._column_info['a4'].values == ('M', 0, 4)
        assert df_mix2._column_info['a5'].values == ('m', 0, 5)


class TestColumns:
    df1 = dx.DataFrame({'a': [1, 5, 7, 11],
                        'b': ['eleni', 'teddy', 'niko', 'penny'],
                        'c': [nan, 5.4, -1.1, .045],
                        'd': [True, False, False, True]})

    def test_set_columns_attr(self):
        df1 = self.df1.copy()
        df1.columns = ['z', 'y', 'x', 'w']
        df2 = dx.DataFrame({'z': [1, 5, 7, 11],
                            'y': ['eleni', 'teddy', 'niko', 'penny'],
                            'x': [nan, 5.4, -1.1, .045],
                            'w': [True, False, False, True]},
                           columns=['z', 'y', 'x', 'w'])
        assert_frame_equal(df1, df2)

        with pytest.raises(ValueError):
            self.df1.columns = ['sdf', 'er']

        with pytest.raises(ValueError):
            self.df1.columns = ['sdf', 'er', 'ewr', 'sdf']

        with pytest.raises(TypeError):
            self.df1.columns = [1, 2, 3, 4]

    def test_get_columns(self):
        columns = self.df1.columns
        assert (columns == ['a', 'b', 'c', 'd'])


class TestValues:
    df1 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': [nan, 5.4, -1.1, .045]})
    df2 = dx.DataFrame({'a': [1, 5, 7, 11],
                        'b': [nan, 5.4, -1.1, .045],
                        'c': ['ted', 'fred', 'ted', 'fred']})

    def test_get_values(self):
        values1 = self.df1.values
        values2 = np.array([[1, 5, 7, 11], [nan, 5.4, -1.1, .045]]).T
        assert_array_equal(values1, values2)

        a = np.random.rand(100, 5)
        df = dx.DataFrame(a)
        assert_array_equal(df.values, a)

        values1 = self.df2.values
        values2 = np.array([[1, 5, 7, 11],
                            [nan, 5.4, -1.1, .045],
                            ['ted', 'fred', 'ted', 'fred']], dtype='O').T
        assert_array_equal(values1, values2)

    def test_shape(self):
        shape = self.df1.shape
        assert shape == (4, 2)

        a = np.random.rand(100, 5)
        df = dx.DataFrame(a)
        assert df.shape == (100, 5)

    def test_size(self):
        assert (self.df1.size == 8)

        a = np.random.rand(100, 5)
        df = dx.DataFrame(a)
        assert df.size == 500

    def test_to_dict(self):
        d1 = self.df1.to_dict('array')
        d2 = {'a': np.array([1, 5, 7, 11]),
              'b': np.array([nan, 5.4, -1.1, .045])}
        for key, arr in d1.items():
            assert_array_equal(arr, d2[key])

        d1 = self.df1.to_dict('list')
        d2 = {'a': [1, 5, 7, 11],
              'b': [nan, 5.4, -1.1, .045]}
        assert_dict_list(d1, d2)

    def test_copy(self):
        df2 = self.df1.copy()
        assert_frame_equal(self.df1, df2)


df = dx.DataFrame({'a': [1, 2, 5, 9, 3, 4, 5, 1],
                   'b': [1.5, 8, 9, 1, 2, 3, 2, 8],
                   'c': list('abcdefgh'),
                   'd': [True, False, True, False] * 2,
                   'e': [10, 20, 30, 4, 5, 6, 7, 8],
                   'f': [1., 3, 3, 3, 11, 4, 5, 1],
                   'g': list('xyxxyyxy'),
                   'h': [3, 4, 5, 6, 7, 8, 9, 0]},
                  columns=list('abcdefgh'))


class TestScalarSelection:

    def test_scalar_selection(self):
        assert (df[5, -1] == 8)
        assert (df[3, 2] == 'd')
        assert (df[4, 'g'] == 'y')
        assert (df[1, 1] == 8)
        assert (df[3, 'h'] == 6)
        assert (df[0, 'e'] == 10)
        assert (df[0, 'd'] == True)


class TestRowOnlySelection:

    def test_scalar_row_selection(self):
        # slice alldf
        df1 = df[:, :]
        assert_frame_equal(df, df1)

        # scalar row
        df1 = df[5, :]
        data = {'a': array([4]), 'b': array([3.]),
                'c': array(['f']),
                'd': array([False], dtype=bool), 'e': array([6]),
                'f': array([4.]), 'g': array(['y']),
                'h': array([8])}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[-1, :]
        data = {'a': [1], 'b': [8.0], 'c': ['h'], 'd': [False],
                'e': [8], 'f': [1.0], 'g': ['y'], 'h': [0]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

    def test_list_of_row_selection(self):
        df1 = df[[0, 4, 5], :]
        data = {'a': [1, 3, 4],
                'b': [1.5, 2.0, 3.0],
                'c': ['a', 'e', 'f'],
                'd': [True, True, False],
                'e': [10, 5, 6],
                'f': [1.0, 11.0, 4.0],
                'g': ['x', 'y', 'y'],
                'h': [3, 7, 8]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[[-4], :]
        data = {'a': [3],
                'b': [2.0],
                'c': ['e'],
                'd': [True],
                'e': [5],
                'f': [11.0],
                'g': ['y'],
                'h': [7]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

    def test_slice_of_row_selection(self):
        df1 = df[2:6, :]
        data = {'a': [5, 9, 3, 4],
                'b': [9.0, 1.0, 2.0, 3.0],
                'c': ['c', 'd', 'e', 'f'],
                'd': [True, False, True, False],
                'e': [30, 4, 5, 6],
                'f': [3.0, 3.0, 11.0, 4.0],
                'g': ['x', 'x', 'y', 'y'],
                'h': [5, 6, 7, 8]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[-3:, :]
        data = {'a': [4, 5, 1],
                'b': [3.0, 2.0, 8.0],
                'c': ['f', 'g', 'h'],
                'd': [False, True, False],
                'e': [6, 7, 8],
                'f': [4.0, 5.0, 1.0],
                'g': ['y', 'x', 'y'],
                'h': [8, 9, 0]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[1:6:3, :]
        data = {'a': [2, 3],
                'b': [8.0, 2.0],
                'c': ['b', 'e'],
                'd': [False, True],
                'e': [20, 5],
                'f': [3.0, 11.0],
                'g': ['y', 'y'],
                'h': [4, 7]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)


class TestColumnOnlySelection:

    def test_scalar_col_selection(self):
        df1 = df[:, 4]
        data = {'e': [10, 20, 30, 4, 5, 6, 7, 8]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[:, -2]
        data = {'g': ['x', 'y', 'x', 'x', 'y', 'y', 'x', 'y']}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[:, 'd']
        data = {'d': [True, False, True, False, True, False, True, False]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        with pytest.raises(KeyError):
            df[:, 'asdf']

    def test_list_of_integer_col_selection(self):
        df1 = df[:, [4, 6, 1]]
        data = {'b': [1.5, 8.0, 9.0, 1.0, 2.0, 3.0, 2.0, 8.0],
                'e': [10, 20, 30, 4, 5, 6, 7, 8],
                'g': ['x', 'y', 'x', 'x', 'y', 'y', 'x', 'y']}
        df2 = dx.DataFrame(data, columns=['e', 'g', 'b'])
        assert_frame_equal(df1, df2)

        df1 = df[:, [3]]
        data = {'d': [True, False, True, False, True, False, True, False]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

    def test_list_of_string_col_selection(self):
        df1 = df[:, ['b', 'd', 'a']]
        data = {'a': [1, 2, 5, 9, 3, 4, 5, 1],
                'b': [1.5, 8.0, 9.0, 1.0, 2.0, 3.0, 2.0, 8.0],
                'd': [True, False, True, False, True, False, True, False]}
        df2 = dx.DataFrame(data, columns=['b', 'd', 'a'])
        assert_frame_equal(df1, df2)

        df1 = df[:, ['a']]
        data = {'a': [1, 2, 5, 9, 3, 4, 5, 1]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

    def test_list_of_string_and_integer_col_selection(self):
        df1 = df[:, ['b', 5]]
        data = {'b': [1.5, 8.0, 9.0, 1.0, 2.0, 3.0, 2.0, 8.0],
                'f': [1.0, 3.0, 3.0, 3.0, 11.0, 4.0, 5.0, 1.0]}
        df2 = dx.DataFrame(data, columns=['b', 'f'])
        assert_frame_equal(df1, df2)

        df1 = df[:, [-2, 'c', 0, 'd']]
        data = {'a': [1, 2, 5, 9, 3, 4, 5, 1],
                'c': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
                'd': [True, False, True, False, True, False, True, False],
                'g': ['x', 'y', 'x', 'x', 'y', 'y', 'x', 'y']}
        df2 = dx.DataFrame(data, columns=['g', 'c', 'a', 'd'])
        assert_frame_equal(df1, df2)

        with pytest.raises(ValueError):
            df[:, ['b', 5, 'e', 'f']]

    def test_slice_with_integers_col_selection(self):
        df1 = df[:, 3:6]
        data = {'d': [True, False, True, False, True, False, True, False],
                'e': [10, 20, 30, 4, 5, 6, 7, 8],
                'f': [1.0, 3.0, 3.0, 3.0, 11.0, 4.0, 5.0, 1.0]}
        df2 = dx.DataFrame(data, columns=['d', 'e', 'f'])
        assert_frame_equal(df1, df2)

        df1 = df[:, -4::2]
        data = {'e': [10, 20, 30, 4, 5, 6, 7, 8],
                'g': ['x', 'y', 'x', 'x', 'y', 'y', 'x', 'y']}
        df2 = dx.DataFrame(data, columns=['e', 'g'])
        assert_frame_equal(df1, df2)

    def test_slice_with_labels_col_selection(self):
        df1 = df[:, 'c':'f']
        data = {'c': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
                'd': [True, False, True, False, True, False, True, False],
                'e': [10, 20, 30, 4, 5, 6, 7, 8],
                'f': [1.0, 3.0, 3.0, 3.0, 11.0, 4.0, 5.0, 1.0]}
        df2 = dx.DataFrame(data, columns=['c', 'd', 'e', 'f'])
        assert_frame_equal(df1, df2)

        df1 = df[:, :'b']
        data = {'a': [1, 2, 5, 9, 3, 4, 5, 1],
                'b': [1.5, 8.0, 9.0, 1.0, 2.0, 3.0, 2.0, 8.0]}
        df2 = dx.DataFrame(data, columns=['a', 'b'])
        assert_frame_equal(df1, df2)

        df1 = df[:, 'g':'b':-2]
        data = {'c': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
                'e': [10, 20, 30, 4, 5, 6, 7, 8],
                'g': ['x', 'y', 'x', 'x', 'y', 'y', 'x', 'y']}
        df2 = dx.DataFrame(data, columns=['g', 'e', 'c'])
        assert_frame_equal(df1, df2)

    def test_slice_labels_and_integer_col_selection(self):
        df1 = df[:, 'c':5]
        data = {'c': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
                'd': [True, False, True, False, True, False, True, False],
                'e': [10, 20, 30, 4, 5, 6, 7, 8]}
        df2 = dx.DataFrame(data, columns=['c', 'd', 'e'])
        assert_frame_equal(df1, df2)

        df1 = df[:, 6:'d':-1]
        data = {'d': [True, False, True, False, True, False, True, False],
                'e': [10, 20, 30, 4, 5, 6, 7, 8],
                'f': [1.0, 3.0, 3.0, 3.0, 11.0, 4.0, 5.0, 1.0],
                'g': ['x', 'y', 'x', 'x', 'y', 'y', 'x', 'y']}
        df2 = dx.DataFrame(data, columns=['g', 'f', 'e', 'd'])
        assert_frame_equal(df1, df2)

    def test_head_tail(self):
        df1 = df.head()
        df2 = dx.DataFrame({'a': [1, 2, 5, 9, 3],
                            'b': [1.5, 8, 9, 1, 2],
                            'c': list('abcde'),
                            'd': [True, False, True, False, True],
                            'e': [10, 20, 30, 4, 5],
                            'f': [1., 3, 3, 3, 11],
                            'g': list('xyxxy'),
                            'h': [3, 4, 5, 6, 7]},
                           columns=list('abcdefgh'))

        assert_frame_equal(df1, df2)

        df1 = df.head(2)
        df2 = dx.DataFrame({'a': [1, 2],
                            'b': [1.5, 8],
                            'c': list('ab'),
                            'd': [True, False],
                            'e': [10, 20],
                            'f': [1., 3],
                            'g': list('xy'),
                            'h': [3, 4]},
                           columns=list('abcdefgh'))
        assert_frame_equal(df1, df2)

        df1 = df.tail(3)
        df2 = dx.DataFrame({'a': [4, 5, 1],
                            'b': [3., 2, 8],
                            'c': list('fgh'),
                            'd': [False, True, False],
                            'e': [6, 7, 8],
                            'f': [4., 5, 1],
                            'g': list('yxy'),
                            'h': [8, 9, 0]},
                           columns=list('abcdefgh'))
        assert_frame_equal(df1, df2)


class TestSimultaneousRowColumnSelection:

    def test_scalar_row_with_list_slice_column_selection(self):
        df1 = df[3, [4, 5, 6]]
        data = {'e': [4], 'f': [3.0], 'g': ['x']}
        df2 = dx.DataFrame(data, columns=['e', 'f', 'g'])
        assert_frame_equal(df1, df2)

        df1 = df[1, [-1]]
        data = {'h': [4]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[0, ['g', 'd']]
        data = {'d': [True], 'g': ['x']}
        df2 = dx.DataFrame(data, columns=['g', 'd'])
        assert_frame_equal(df1, df2)

        df1 = df[0, ['d']]
        data = {'d': [True]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[-2, 2:6]
        data = {'c': ['g'], 'd': [True], 'e': [7], 'f': [5.0]}
        df2 = dx.DataFrame(data, columns=['c', 'd', 'e', 'f'])
        assert_frame_equal(df1, df2)

        df1 = df[4, 'f':'b':-1]
        data = {'b': [2.0], 'c': ['e'], 'd': [True], 'e': [5], 'f': [11.0]}
        df2 = dx.DataFrame(data, columns=['f', 'e', 'd', 'c', 'b'])
        assert_frame_equal(df1, df2)

    def test_scalar_column_with_list_slice_row_selection(self):
        df1 = df[[4, 6], 2]
        data = {'c': ['e', 'g']}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[[4], 2]
        data = {'c': ['e']}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[[5, 2], 'f']
        data = {'f': [4.0, 3.0]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[3:, 'f']
        data = {'f': [3.0, 11.0, 4.0, 5.0, 1.0]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

        df1 = df[5::-2, 'b']
        data = {'b': [3.0, 1.0, 8.0]}
        df2 = dx.DataFrame(data)
        assert_frame_equal(df1, df2)

    def test_list_slice_row_with_list_slice_column_selection(self):
        df1 = df[[3, 4], [0, 6]]
        data = {'a': [9, 3], 'g': ['x', 'y']}
        df2 = dx.DataFrame(data, columns=['a', 'g'])
        assert_frame_equal(df1, df2)

        df1 = df[3::3, [6, 3, 1, 5]]
        data = {'b': [1.0, 2.0], 'd': [False, True],
                'f': [3.0, 5.0], 'g': ['x', 'x']}
        df2 = dx.DataFrame(data, columns=['g', 'd', 'b', 'f'])
        assert_frame_equal(df1, df2)

        df1 = df[3:, 'c':]
        data = {'c': ['d', 'e', 'f', 'g', 'h'],
                'd': [False, True, False, True, False],
                'e': [4, 5, 6, 7, 8],
                'f': [3.0, 11.0, 4.0, 5.0, 1.0],
                'g': ['x', 'y', 'y', 'x', 'y'],
                'h': [6, 7, 8, 9, 0]}
        df2 = dx.DataFrame(data, columns=['c', 'd', 'e', 'f', 'g', 'h'])
        assert_frame_equal(df1, df2)


class TestBooleanSelection:
    df = dx.DataFrame({'a': [0, 0, 5, 9, 3, 4, 5, 1],
                       'b': [0, 1.512344353, 8, 9, nan, 3, 2, 8],
                       'c': [''] + list('bgggzgh'),
                       'd': [False, False, True, False] * 2,
                       'e': [0, 20, 30, 4, 5, 6, 7, 8],
                       'f': [0., 3, 3, 3, 11, 4, 5, 1],
                       'g': ['', None, 'ad', 'effd', 'ef', None, 'ett', 'zzzz'],
                       'h': [0, 4, 5, 6, 7, 8, 9, 0],
                       'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
                       'j': np.zeros(8, dtype='int'),
                       'k': np.ones(8) - 1,
                       'l': [nan] * 8},
                      columns=list('abcdefghijkl'))

    def test_integer_condition(self):
        criteria = self.df[:, 'a'] > 4
        df1 = self.df[criteria, :]
        df2 = self.df[[2, 3, 6], :]
        assert_frame_equal(df1, df2)

        criteria = self.df[:, 'a'] == 0
        df1 = self.df[criteria, :]
        df2 = self.df[[0, 1], :]
        assert_frame_equal(df1, df2)

        criteria = (self.df[:, 'a'] > 2) & (self.df[:, 'i'] < 6)
        df1 = self.df[criteria, :]
        df2 = self.df[[3, 4, 5, 6], :]
        assert_frame_equal(df1, df2)

        criteria = (self.df[:, 'a'] > 2) | (self.df[:, 'i'] < 6)
        df1 = self.df[criteria, :]
        df2 = self.df[[0, 2, 3, 4, 5, 6], :]
        assert_frame_equal(df1, df2)

        criteria = ~((self.df[:, 'a'] > 2) | (self.df[:, 'i'] < 6))
        df1 = self.df[criteria, :]
        df2 = self.df[[1, 7], :]
        assert_frame_equal(df1, df2)

        criteria = ~((self.df[:, 'a'] > 2) | (self.df[:, 'i'] < 6))
        df1 = self.df[criteria, ['d', 'b']]
        df2 = dx.DataFrame({'b': [1.512344353, 8],
                            'd': [False, False]}, columns=['d', 'b'])
        assert_frame_equal(df1, df2)

    def test_list_of_booleans(self):
        criteria = [False, True, False, True, False, True, False, True]
        df1 = self.df[criteria, :]
        df2 = self.df[[1, 3, 5, 7], :]
        assert_frame_equal(df1, df2)

        criteria = [False, True, False, True, False, True, False]
        with pytest.raises(ValueError):
            self.df[criteria, :]

        criteria = [False, True, False, True, False, True] * 2
        df1 = self.df[:, criteria]
        df2 = self.df[:, list(range(1, 12, 2))]
        assert_frame_equal(df1, df2)

        criteria_row = [False, False, True, False, True, True, False, False]
        criteria_col = [False, True, False, True, False, True] * 2
        df1 = self.df[criteria_row, criteria_col]
        df2 = self.df[[2, 4, 5], list(range(1, 12, 2))]
        assert_frame_equal(df1, df2)

        with pytest.raises(TypeError):
            self.df[[0, 5], [False, 5]]

        with pytest.raises(ValueError):
            self.df[:, [True, False, True, False]]

        df1 = self.df[self.df[:, 'c'] == 'g', ['d', 'j']]
        df2 = dx.DataFrame({'d': [True, False, False, True],
                            'j': [0, 0, 0, 0]}, columns=['d', 'j'])
        assert_frame_equal(df1, df2)

        with np.errstate(invalid='ignore'):
            df1 = self.df[self.df[:, 'b'] < 2, 'b']
            df2 = dx.DataFrame({'b': [0, 1.512344353]})
            assert_frame_equal(df1, df2)

    def test_boolean_column_selection(self):
        data = {'a': [0, 0, 5, 9, 3, 4, 5, 1],
                'b': [0, 1.512344353, 8, 9, np.nan, 3, 2, 8],
                'c': [''] + list('bgggzgh'),
                'd': [False, False, True, False] * 2,
                'e': [0, 20, 30, 4, 5, 6, 7, 8],
                'f': [0., 3, 3, 3, 11, 4, 5, 1],
                'g': ['', None, 'ad', 'effd', 'ef', None, 'ett', 'zzzz'],
                'h': [0, 4, 5, 6, 7, 8, 9, 0],
                'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
                'j': np.zeros(8, dtype='int'),
                'k': np.ones(8) - 1,
                'l': [np.nan] * 8}

        df = dx.DataFrame(data)
        df1 = df.select_dtypes('int')
        df_criteria = df1[1, :] == 0
        df1 = df1[:, df_criteria]
        df2 = dx.DataFrame({'a': [0, 0, 5, 9, 3, 4, 5, 1],
                            'j': np.zeros(8, dtype='int')})
        assert_frame_equal(df1, df2)

        criteria = np.array([False, False, False, True, True, False,
                             False, False, False, False, False, False])
        df1 = df[-3:, criteria]
        df2 = dx.DataFrame({'d': [False, True, False],
                            'e': [6, 7, 8]})
        assert_frame_equal(df1, df2)


class TestSetItem:
    df = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                       'd': [True, False]})

    df1 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                        'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})

    def test_setitem_scalar(self):
        df1 = self.df.copy()
        df1[0, 0] = -99
        df2 = dx.DataFrame({'a': [-99, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1[0, 'b'] = 'pen'
        df2 = dx.DataFrame({'a': [-99, 5], 'b': ['pen', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1[1, 'b'] = None
        df2 = dx.DataFrame({'a': [-99, 5], 'b': ['pen', None], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        with pytest.raises(TypeError):
            df1 = self.df.copy()
            df1[0, 0] = 'sfa'

        df1 = self.df.copy()
        df1[0, 'c'] = 4.3
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [4.3, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[0, 'a'] = nan
        df2 = dx.DataFrame({'a': [nan, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[1, 'a'] = -9.9
        df2 = dx.DataFrame({'a': [1, -9.9], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

    def test_setitem_entire_column_one_value(self):
        df1 = self.df.copy()
        df1[:, 'e'] = 5
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [5, 5]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = nan
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [nan, nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = 'grasshopper'
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': ['grasshopper', 'grasshopper']})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = True
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [True, True]})
        assert_frame_equal(df1, df2)

    def test_setitem_entire_new_colunm_from_array(self):
        df1 = self.df.copy()
        df1[:, 'e'] = np.array([9, 99])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [9, 99]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = [9, np.nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [9, np.nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = np.array([True, False])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = np.array(['poop', nan], dtype='O')
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': ['poop', nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = np.array(['poop', 'pants'])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': ['poop', 'pants']})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = np.array([nan, nan])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [nan, nan]})
        assert_frame_equal(df1, df2)

    def test_setitem_entire_new_colunm_from_list(self):
        df1 = self.df.copy()
        df1[:, 'e'] = [9, 99]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [9, 99]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = [9, np.nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [9, np.nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = [True, False]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = ['poop', nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': ['poop', nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = ['poop', 'pants']
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': ['poop', 'pants']})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'e'] = [nan, nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False], 'e': [nan, nan]})
        assert_frame_equal(df1, df2)

    def test_setitem_entire_old_column_from_array(self):
        df1 = self.df.copy()
        df1[:, 'd'] = np.array([9, 99])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [9, 99]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        d = np.array([9, np.nan])
        df1[:, 'd'] = d
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': d})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'd'] = np.array([True, False])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'd'] = np.array(['poop', nan], dtype='O')
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': ['poop', nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'a'] = np.array(['poop', 'pants'], dtype='O')
        df2 = dx.DataFrame({'a': ['poop', 'pants'], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'b'] = np.array([nan, nan])
        df2 = dx.DataFrame({'a': [1, 5], 'b': [nan, nan], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'c'] = np.array([False, False])
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [False, False],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        with pytest.raises(ValueError):
            df1[:, 'b'] = np.array([1, 2, 3])

        with pytest.raises(ValueError):
            df1[:, 'b'] = np.array([1])

        with pytest.raises(TypeError):
            df1[:, 'a'] = np.array([5, {1, 2, 3}])

    def test_setitem_entire_new_column_from_df(self):
        df1 = self.df1.copy()
        df1[:, 'a_bool'] = df1[:, 'a'] > 3

        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True],
                            'a_bool': [False, True, True, True]},
                           columns=['a', 'b', 'c', 'd', 'a_bool'])
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[:, 'a2'] = df1[:, 'a'] + 5

        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True],
                            'a2': [6, 10, 12, 16]},
                           columns=['a', 'b', 'c', 'd', 'a2'])
        assert_frame_equal(df1, df2)

    def test_setitem_entire_old_column_from_list(self):
        df1 = self.df.copy()
        df1[:, 'd'] = [9, 99]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [9, 99]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'd'] = [9, np.nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [9, np.nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'd'] = [True, False]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'd'] = ['poop', nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': ['poop', nan]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'a'] = ['poop', 'pants']
        df2 = dx.DataFrame({'a': ['poop', 'pants'], 'b': ['eleni', 'teddy'], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'b'] = [nan, nan]
        df2 = dx.DataFrame({'a': [1, 5], 'b': [nan, nan], 'c': [nan, 5.4],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.copy()
        df1[:, 'c'] = [False, False]
        df2 = dx.DataFrame({'a': [1, 5], 'b': ['eleni', 'teddy'], 'c': [False, False],
                            'd': [True, False]})
        assert_frame_equal(df1, df2)

        with pytest.raises(ValueError):
            self.df[:, 'b'] = [1, 2, 3]

        with pytest.raises(ValueError):
            self.df[:, 'b'] = [1]

        with pytest.raises(TypeError):
            self.df[:, 'a'] = [5, {1, 2, 3}]

    def test_setitem_simultaneous_row_and_column(self):
        df1 = self.df1.copy()
        df1[[0, 1], 'a'] = [9, 10]
        df2 = dx.DataFrame({'a': [9, 10, 7, 11], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[[0, -1], 'a'] = np.array([9, 10.5])
        df2 = dx.DataFrame({'a': [9, 5, 7, 10.5], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[2:, 'b'] = np.array(['NIKO', 'PENNY'])
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', 'NIKO', 'PENNY'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[2, ['b', 'c']] = ['NIKO', 9.3]
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', 'NIKO', 'penny'],
                            'c': [nan, 5.4, 9.3, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[2, ['c', 'b']] = [9.3, None]
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', None, 'penny'],
                            'c': [nan, 5.4, 9.3, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[[1, -1], 'b':'d'] = [['TEDDY', nan, True], [nan, 5.5, False]]
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'TEDDY', 'niko', nan],
                            'c': [nan, nan, -1.1, 5.5], 'd': [True, True, False, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[1:-1, 'a':'d':2] = [[nan, 4], [3, 99]]

        df2 = dx.DataFrame({'a': [1, nan, 3, 11], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                            'c': [nan, 4, 99, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

    def test_testitem_boolean(self):
        df1 = self.df1.copy()
        criteria = df1[:, 'a'] > 4
        df1[criteria, 'b'] = 'TEDDY'
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'TEDDY', 'TEDDY', 'TEDDY'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        criteria = df1[:, 'a'] > 4
        df1[criteria, 'b'] = ['A', 'B', 'C']
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'A', 'B', 'C'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        criteria = df1[:, 'a'] == 5
        df1[criteria, :] = [nan, 'poop', 2.2, True]
        df2 = dx.DataFrame({'a': [1, nan, 7, 11], 'b': ['eleni', 'poop', 'niko', 'penny'],
                            'c': [nan, 2.2, -1.1, .045], 'd': [True, True, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        with pytest.raises(ValueError):
            df1[df1[:, 'a'] > 2, 'b'] = np.array(['aa', 'bb', 'cc', 'dd'])

        df1 = self.df1.copy()
        criteria = df1[:, 'a'] > 6
        df1[criteria, 'b'] = np.array(['food', nan], dtype='O')
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'teddy', 'food', nan],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[df1[:, 'a'] < 6, ['d', 'c', 'a']] = [[False, nan, 5.3], [False, 44, 4]]
        df2 = dx.DataFrame({'a': [5.3, 4, 7, 11], 'b': ['eleni', 'teddy', 'niko', 'penny'],
                            'c': [nan, 44, -1.1, .045], 'd': [False, False, False, True]})
        assert_frame_equal(df1, df2)

    def test_setitem_other_df(self):
        df_other = dx.DataFrame({'z': [1, 10, 9, 50], 'y': ['dont', 'be a', 'silly', 'sausage']})

        df1 = self.df1.copy()
        df1[:, ['a', 'b']] = df_other
        df2 = dx.DataFrame({'a': [1, 10, 9, 50], 'b': ['dont', 'be a', 'silly', 'sausage'],
                            'c': [nan, 5.4, -1.1, .045], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df1.copy()
        df1[[1, 3], ['c', 'b']] = df_other[[0, 2], :]
        df2 = dx.DataFrame({'a': [1, 5, 7, 11], 'b': ['eleni', 'dont', 'niko', 'silly'],
                            'c': [nan, 1, -1.1, 9], 'd': [True, False, False, True]})
        assert_frame_equal(df1, df2)

        with pytest.raises(ValueError):
            df1 = self.df1.copy()
            df1[[1, 3], ['c', 'b']] = df_other[[0], :]


class TestSelectDtypes:
    data = {'a': [0, 0, 5, 9, 3, 4, 5, 1],
            'b': [0, 1.512344353, 8, 9, np.nan, 3, 2, 8],
            'c': [''] + list('bgggzgh'),
            'd': [False, False, True, False] * 2,
            'e': [0, 20, 30, 4, 5, 6, 7, 8],
            'f': [0., 3, 3, 3, 11, 4, 5, 1],
            'g': ['', None, 'ad', 'effd', 'ef', None, 'ett', 'zzzz'],
            'h': [0, 4, 5, 6, 7, 8, 9, 0],
            'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
            'j': np.zeros(8, dtype='int'),
            'k': np.ones(8) - 1,
            'l': [np.nan] * 8}

    df = dx.DataFrame(data, columns=list('abcdefghijkl'))

    def test_selectdtypes_ints(self):
        df1 = self.df.select_dtypes('int')
        df2 = dx.DataFrame({'a': [0, 0, 5, 9, 3, 4, 5, 1],
                            'e': [0, 20, 30, 4, 5, 6, 7, 8],
                            'h': [0, 4, 5, 6, 7, 8, 9, 0],
                            'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
                            'j': np.zeros(8, dtype='int')},
                           columns=list('aehij'))

        assert_frame_equal(df1, df2)

    def test_selectdtypes_float(self):
        df1 = self.df.select_dtypes('float')
        df2 = dx.DataFrame({'b': [0, 1.512344353, 8, 9, np.nan, 3, 2, 8],
                            'f': [0., 3, 3, 3, 11, 4, 5, 1],
                            'k': np.ones(8) - 1,
                            'l': [np.nan] * 8},
                           columns=list('bfkl'))
        assert_frame_equal(df1, df2)

    def test_selectdtypes_bool(self):
        df1 = self.df.select_dtypes('bool')
        df2 = dx.DataFrame({'d': [False, False, True, False] * 2})
        assert_frame_equal(df1, df2)

    def test_selectdtypes_str(self):
        df1 = self.df.select_dtypes('str')
        df2 = dx.DataFrame({'c': [''] + list('bgggzgh'),
                            'g': ['', None, 'ad', 'effd', 'ef', None, 'ett', 'zzzz']},
                           columns=['c', 'g'])
        assert_frame_equal(df1, df2)

    def test_selectdtypes_number(self):
        df1 = self.df.select_dtypes('number')
        df2 = dx.DataFrame({'a': [0, 0, 5, 9, 3, 4, 5, 1],
                            'b': [0, 1.512344353, 8, 9, np.nan, 3, 2, 8],
                            'e': [0, 20, 30, 4, 5, 6, 7, 8],
                            'f': [0., 3, 3, 3, 11, 4, 5, 1],
                            'h': [0, 4, 5, 6, 7, 8, 9, 0],
                            'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
                            'j': np.zeros(8, dtype='int'),
                            'k': np.ones(8) - 1,
                            'l': [np.nan] * 8},
                           columns=list('abefhijkl'))
        assert_frame_equal(df1, df2)

    def test_get_dtypes(self):
        df1 = self.df.dtypes
        df2 = dx.DataFrame({'Column Name': list('abcdefghijkl'),
                            'Data Type': ['int', 'float', 'str', 'bool', 'int', 'float',
                                          'str', 'int', 'int', 'int', 'float', 'float']},
                           columns=['Column Name', 'Data Type'])
        assert_frame_equal(df1, df2)

    def test_selectdtypes_multiple(self):
        df1 = self.df.select_dtypes(['bool', 'int'])
        df2 = dx.DataFrame({'a': [0, 0, 5, 9, 3, 4, 5, 1],
                            'd': [False, False, True, False] * 2,
                            'e': [0, 20, 30, 4, 5, 6, 7, 8],
                            'h': [0, 4, 5, 6, 7, 8, 9, 0],
                            'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
                            'j': np.zeros(8, dtype='int')}, columns=list('adehij'))
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes(['float', 'str'])
        df2 = dx.DataFrame({'b': [0, 1.512344353, 8, 9, np.nan, 3, 2, 8],
                            'c': [''] + list('bgggzgh'),
                            'f': [0., 3, 3, 3, 11, 4, 5, 1],
                            'g': ['', None, 'ad', 'effd', 'ef', None, 'ett', 'zzzz'],
                            'k': np.ones(8) - 1,
                            'l': [np.nan] * 8},
                           columns=list('bcfgkl'))
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes(exclude='float')
        df2 = dx.DataFrame({'a': [0, 0, 5, 9, 3, 4, 5, 1],
                            'c': [''] + list('bgggzgh'),
                            'd': [False, False, True, False] * 2,
                            'e': [0, 20, 30, 4, 5, 6, 7, 8],
                            'g': ['', None, 'ad', 'effd', 'ef', None, 'ett', 'zzzz'],
                            'h': [0, 4, 5, 6, 7, 8, 9, 0],
                            'i': np.array([0, 7, 6, 5, 4, 3, 2, 11]),
                            'j': np.zeros(8, dtype='int')})
        assert_frame_equal(df1, df2)


class TestArithmeticOperations:
    df = dx.DataFrame({'a': [0, 0, 5],
                       'b': [0, 1.5, nan],
                       'c': [''] + list('bg'),
                       'd': [False, False, True],
                       'e': ['', None, 'ad'],
                       'f': [0, 4, 5],
                       'g': np.zeros(3, dtype='int'),
                       'h': [np.nan] * 3})

    def test_add_number_frame(self):
        with pytest.raises(TypeError):
            self.df + 5

        df1 = self.df.select_dtypes('int') + 5
        df2 = dx.DataFrame({'a': [5, 5, 10],
                            'f': [5, 9, 10],
                            'g': np.zeros(3, dtype='int') + 5},
                           columns=['a', 'f', 'g'])
        assert_frame_equal(df1, df2)

        df1 = 5 + self.df.select_dtypes('int')
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes('number') + 5
        df2 = dx.DataFrame({'a': [5, 5, 10],
                            'b': [5, 6.5, nan],
                            'f': [5, 9, 10],
                            'g': np.zeros(3, dtype='int') + 5,
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

        df1 = 5 + self.df.select_dtypes('number')
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes(['number', 'bool']) + 5
        df2 = dx.DataFrame({'a': [5, 5, 10],
                            'b': [5, 6.5, nan],
                            'd': [5, 5, 6],
                            'f': [5, 9, 10],
                            'g': np.zeros(3, dtype='int') + 5,
                            'h': [np.nan] * 3},
                           columns=list('abdfgh'))
        assert_frame_equal(df1, df2)

        df1 = 5 + self.df.select_dtypes(['number', 'bool'])
        assert_frame_equal(df1, df2)

    def test_add_string_frame(self):
        df1 = self.df.select_dtypes('str') + 'aaa'
        df2 = dx.DataFrame({'c': ['aaa', 'baaa', 'gaaa'],
                            'e': ['aaa', None, 'adaaa']})
        assert_frame_equal(df1, df2)

        df1 = 'aaa' + self.df.select_dtypes('str')
        df2 = dx.DataFrame({'c': ['aaa', 'aaab', 'aaag'],
                            'e': ['aaa', None, 'aaaad']})
        assert_frame_equal(df1, df2)

    def test_comparison_string_frame(self):
        df1 = self.df.select_dtypes('str') > 'boo'
        df2 = dx.DataFrame({'c': [False, False, True],
                            'e': [False, False, False]})
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes('str') < 'boo'
        df2 = dx.DataFrame({'c': [True, True, False],
                            'e': [True, False, True]})
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes('str') == 'b'
        df2 = dx.DataFrame({'c': [False, True, False],
                            'e': [False, False, False]})
        assert_frame_equal(df1, df2)

    def test_subtract_frame(self):
        with pytest.raises(TypeError):
            self.df - 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') - 10

        df1 = self.df.select_dtypes('int') - 5
        df2 = dx.DataFrame({'a': [-5, -5, 0],
                            'f': [-5, -1, 0],
                            'g': np.zeros(3, dtype='int') - 5},
                           columns=['a', 'f', 'g'])
        assert_frame_equal(df1, df2)

        df1 = 5 - self.df.select_dtypes('int')
        df2 = dx.DataFrame({'a': [5, 5, 0],
                            'f': [5, 1, 0],
                            'g': 5 - np.zeros(3, dtype='int')},
                           columns=['a', 'f', 'g'])
        assert_frame_equal(df1, df2)

        df1 = self.df.select_dtypes(['number', 'bool']) - 5
        df2 = dx.DataFrame({'a': [-5, -5, 0],
                            'b': [-5, -3.5, nan],
                            'd': [-5, -5, -4],
                            'f': [-5, -1, 0],
                            'g': np.zeros(3, dtype='int') - 5,
                            'h': [np.nan] * 3},
                           columns=list('abdfgh'))
        assert_frame_equal(df1, df2)

        df1 = 5 - self.df.select_dtypes(['number', 'bool'])
        df2 = dx.DataFrame({'a': [5, 5, 0],
                            'b': [5, 3.5, nan],
                            'd': [5, 5, 4],
                            'f': [5, 1, 0],
                            'g': 5 - np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3},
                           columns=list('abdfgh'))
        assert_frame_equal(df1, df2)

    def test_mult_frame(self):
        df1 = self.df * 2
        df2 = dx.DataFrame({'a': [0, 0, 10],
                            'b': [0, 3, nan],
                            'c': ['', 'bb', 'gg'],
                            'd': [0, 0, 2],
                            'e': ['', None, 'adad'],
                            'f': [0, 8, 10],
                            'g': np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3})
        assert_frame_equal(df1, df2)

        df1 = 2 * self.df
        df2 = dx.DataFrame({'a': [0, 0, 10],
                            'b': [0, 3, nan],
                            'c': ['', 'bb', 'gg'],
                            'd': [0, 0, 2],
                            'e': ['', None, 'adad'],
                            'f': [0, 8, 10],
                            'g': np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3})
        assert_frame_equal(df1, df2)

    def test_truediv_frame(self):
        with pytest.raises(TypeError):
            self.df / 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') / 10

        with pytest.raises(TypeError):
            self.df / 'asdf'

        df1 = self.df.select_dtypes('number') / 2
        df2 = dx.DataFrame({'a': [0, 0, 2.5],
                            'b': [0, .75, nan],
                            'f': [0, 2, 2.5],
                            'g': np.zeros(3),
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

        df1 = 10 / self.df.select_dtypes('number')
        df2 = dx.DataFrame({'a': [np.inf, np.inf, 2],
                            'b': [np.inf, 10 / 1.5, nan],
                            'f': [np.inf, 2.5, 2],
                            'g': [np.inf] * 3,
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_floordiv_frame(self):
        with pytest.raises(TypeError):
            self.df // 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') // 10

        with pytest.raises(TypeError):
            self.df // 'asdf'

        df = dx.DataFrame({'a': [0, 0, 10],
                           'b': [0, 20, nan],
                           'f': [0, 100, 10],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3},
                          columns=list('abfgh'))

        df1 = df // 3
        df2 = dx.DataFrame({'a': [0, 0, 3],
                            'b': [0, 6, nan],
                            'f': [0, 33, 3],
                            'g': np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_pow_frame(self):
        with pytest.raises(TypeError):
            self.df ** 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') ** 10

        with pytest.raises(TypeError):
            self.df ** 'asdf'

        df = dx.DataFrame({'a': [0, 0, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3},
                          columns=list('abfgh'))
        df1 = df ** 2
        df2 = dx.DataFrame({'a': [0, 0, 100],
                            'b': [0, 4, nan],
                            'f': [0, 100, 9],
                            'g': np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))

        assert_frame_equal(df1, df2)

        df1 = 2 ** df
        df2 = dx.DataFrame({'a': [1, 1, 1024],
                            'b': [1, 4, nan],
                            'f': [1, 1024, 8],
                            'g': np.ones(3, dtype='int'),
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_mod_division_frame(self):
        with pytest.raises(TypeError):
            self.df % 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') % 10

        with pytest.raises(TypeError):
            self.df % 'asdf'

        df = dx.DataFrame({'a': [6, 7, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3},
                          columns=list('abfgh'))

        df1 = df % 3
        df2 = dx.DataFrame({'a': [0, 1, 1],
                            'b': [0, 2, nan],
                            'f': [0, 1, 0],
                            'g': np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_greater_than(self):
        with pytest.raises(TypeError):
            self.df > 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') > 10

        with pytest.raises(TypeError):
            self.df > 'asdf'

        df = dx.DataFrame({'a': [6, 7, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3},
                          columns=list('abfgh'))

        df1 = df > 3
        df2 = dx.DataFrame({'a': [True, True, True],
                            'b': [False, False, False],
                            'f': [False, True, False],
                            'g': np.zeros(3, dtype='bool'),
                            'h': [False] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_greater_than_equal(self):
        with pytest.raises(TypeError):
            self.df >= 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') >= 10

        with pytest.raises(TypeError):
            self.df >= 'asdf'

        df = dx.DataFrame({'a': [6, 7, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3},
                          columns=list('abfgh'))

        df1 = df >= 3
        df2 = dx.DataFrame({'a': [True, True, True],
                            'b': [False, False, False],
                            'f': [False, True, True],
                            'g': np.zeros(3, dtype='bool'),
                            'h': [False] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_less_than(self):
        with pytest.raises(TypeError):
            self.df < 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') < 10

        with pytest.raises(TypeError):
            self.df < 'asdf'

        df = dx.DataFrame({'a': [6, 7, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3},
                          columns=list('abfgh'))

        df1 = df < 3
        df2 = dx.DataFrame({'a': [False, False, False],
                            'b': [True, True, False],
                            'f': [True, False, False],
                            'g': np.ones(3, dtype='bool'),
                            'h': [False] * 3},
                           columns=list('abfgh'))
        assert_frame_equal(df1, df2)

    def test_less_than_equal(self):
        with pytest.raises(TypeError):
            self.df <= 5

        with pytest.raises(TypeError):
            self.df.select_dtypes('str') <= 10

        with pytest.raises(TypeError):
            self.df <= 'asdf'

        df = dx.DataFrame({'a': [6, 7, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3})
        df1 = df <= 3

        df2 = dx.DataFrame({'a': [False, False, False],
                            'b': [True, True, False],
                            'f': [True, False, True],
                            'g': np.ones(3, dtype='bool'),
                            'h': [False] * 3
                            })
        assert_frame_equal(df1, df2)

    def test_neg_frame(self):
        with pytest.raises(TypeError):
            -self.df

        with pytest.raises(TypeError):
            -self.df.select_dtypes('str')

        df = dx.DataFrame({'a': [6, 7, 10],
                           'b': [0, 2, nan],
                           'f': [0, 10, 3],
                           'g': np.zeros(3, dtype='int'),
                           'h': [np.nan] * 3})
        df1 = -df

        df2 = dx.DataFrame({'a': [-6, -7, -10],
                            'b': [0, -2, nan],
                            'f': [0, -10, -3],
                            'g': np.zeros(3, dtype='int'),
                            'h': [np.nan] * 3})
        assert_frame_equal(df1, df2)

    def test_inplace_operators(self):
        with pytest.raises(NotImplementedError):
            self.df += 5

        with pytest.raises(NotImplementedError):
            self.df -= 5

        with pytest.raises(NotImplementedError):
            self.df *= 5

        with pytest.raises(NotImplementedError):
            self.df /= 5

        with pytest.raises(NotImplementedError):
            self.df //= 5

        with pytest.raises(NotImplementedError):
            self.df **= 5

        with pytest.raises(NotImplementedError):
            self.df %= 5


class TestArithmeticOperatorsDF:
    a = [1, 2]
    b = [-10, 10]
    c = [1.5, 8]
    d = [2.3, np.nan]
    e = list('ab')
    f = [True, False]
    g = [np.timedelta64(x, 'D') for x in range(2)]
    df = dx.DataFrame({'a': a,
                       'b': b,
                       'c': c,
                       'd': d,
                       'e': e,
                       'f': f,
                       'g': g},
                      columns=list('abcdefg'))

    a = [5]
    b = [99]
    c = [2.1]
    d = [np.nan]
    e = ['twoplustwo']
    f = [True]
    g = [np.timedelta64(1000, 'D')]
    df_one_row = dx.DataFrame({'a': a,
                               'b': b,
                               'c': c,
                               'd': d,
                               'e': e,
                               'f': f,
                               'g': g},
                              columns=list('abcdefg'))

    df_one_row_number = df_one_row.select_dtypes('number')
    df_one_col = dx.DataFrame({'COL': [5, 2.1]})
    df_number = df.select_dtypes('number')

    df_number2 = dx.DataFrame({'A': [4, 5],
                               'B': [0, 0],
                               'C': [2, 2],
                               'D': [-2, 4]},
                              columns=list('ABCD'))

    df_strings = dx.DataFrame({'a': ['one', 'two'], 'b': ['three', 'four']})
    df_strings_row = dx.DataFrame({'a': ['MOOP'], 'b': ['DOOP']})
    df_strings_col = dx.DataFrame({'a': ['MOOP', 'DOOP']})

    def test_add_df(self):
        df_answer = dx.DataFrame({'a': np.array([2, 4]),
                                  'b': np.array([-20, 20]),
                                  'c': np.array([3., 16.]),
                                  'd': np.array([4.6, nan]),
                                  'e': np.array(['aa', 'bb'], dtype=object),
                                  'f': np.array([True, False]),
                                  'g': np.array([0, 172800000000000], dtype='timedelta64[ns]')})
        assert_frame_equal(self.df + self.df, df_answer)

        df_answer = dx.DataFrame({'a': array([5, 7]),
                                  'b': array([-10, 10]),
                                  'c': array([3.5, 10.]),
                                  'd': array([0.3, nan])})
        df_result = self.df_number + self.df_number2
        assert_frame_equal(df_result, df_answer)

    def test_add_one_col(self):
        df_answer = dx.DataFrame({'a': np.array([6., 4.1]),
                                  'b': np.array([-5., 12.1]),
                                  'c': np.array([6.5, 10.1]),
                                  'd': np.array([7.3, nan])})
        df_result = self.df_number + self.df_one_col
        assert_frame_equal(df_result, df_answer)

        df_result = self.df_one_col + self.df_number
        assert_frame_equal(df_result, df_answer)

    def test_add_one_row(self):
        df_answer = dx.DataFrame({'a': array([6, 7]),
                                  'b': array([ 89, 109]),
                                  'c': array([ 3.6, 10.1]),
                                  'd': array([nan, nan])})
        df_result = self.df_number + self.df_one_row_number
        assert_frame_equal(df_result, df_answer)

        df_result = self.df_number + self.df_one_row_number
        assert_frame_equal(df_answer, df_result)

    def test_add_string(self):
        df_answer = dx.DataFrame({'a': array(['oneone', 'twotwo'], dtype=object),
                                  'b': array(['threethree', 'fourfour'], dtype=object)})
        df_result = self.df_strings + self.df_strings
        assert_frame_equal(df_answer, df_result)

    def test_add_string_row(self):
        df_answer = dx.DataFrame({'a': array(['oneMOOP', 'twoMOOP'], dtype=object),
                                  'b': array(['threeDOOP', 'fourDOOP'], dtype=object)})
        df_result = self.df_strings + self.df_strings_row
        assert_frame_equal(df_answer, df_result)

        df_answer = dx.DataFrame({'a': array(['MOOPone', 'MOOPtwo'], dtype=object),
                                  'b': array(['DOOPthree', 'DOOPfour'], dtype=object)})
        df_result = self.df_strings_row + self.df_strings
        assert_frame_equal(df_answer, df_result)


class TestMultipleBooleanConditions:
    df = dx.DataFrame({'a': [1, 4, 10, 20],
                       'b': ['a', 'a', 'c', 'c'],
                       'c': [5, 1, 14, 3]})

    def test_and(self):
        df1 = (self.df[:, 'a'] > 5) & (self.df[:, 'a'] < 15)
        df2 = dx.DataFrame({'a': [False, False, True, False]})
        assert_frame_equal(df1, df2)

    def test_or(self):
        df1 = (self.df[:, 'a'] > 5) | (self.df[:, 'c'] < 2)
        df2 = dx.DataFrame({'a': [False, True, True, True]})
        assert_frame_equal(df1, df2)

    def test_invert(self):
        df1 = ~((self.df[:, 'a'] > 5) | (self.df[:, 'c'] < 2))
        df2 = dx.DataFrame({'a': [True, False, False, False]})
        assert_frame_equal(df1, df2)


class TestAsType:
    df = dx.DataFrame({'a': [1, 4, 10, 20],
                       'b': ['a', 'a', 'c', 'c'],
                       'c': [5, 1, 14, 3]})

    def test_to_float(self):
        df1 = self.df.astype({'a': 'float'})
        df2 = dx.DataFrame({'a': [1., 4, 10, 20],
                            'b': ['a', 'a', 'c', 'c'],
                            'c': [5, 1, 14, 3]})
        assert_frame_equal(df1, df2)

        with pytest.raises(ValueError):
            self.df.astype('float')

        df1 = self.df[:, ['a', 'c']].astype('float')
        df2 = dx.DataFrame({'a': [1., 4, 10, 20],
                            'c': [5., 1, 14, 3]})
        assert_frame_equal(df1, df2)

    def test_to_str(self):
        df1 = self.df.astype({'a': 'str'})
        df2 = dx.DataFrame({'a': ['1', '4', '10', '20'],
                            'b': ['a', 'a', 'c', 'c'],
                            'c': [5, 1, 14, 3]})
        assert_frame_equal(df1, df2)

    def test_to_bool(self):
        df = dx.DataFrame({'a': [1, 0, 10, 20],
                           'b': ['a', '', 'c', 'c'],
                           'c': [5, 1, 14, nan]})
        df1 = df.astype('bool')
        df2 = dx.DataFrame({'a': [True, False, True, True],
                            'b': [True, False, True, True],
                            'c': [True, True, True, True]})
        assert_frame_equal(df1, df2)

    def test_hasnans(self):
        df = dx.DataFrame({'a': [1, 0, 10, 20],
                           'b': ['a', nan, 'c', 'c'],
                           'c': [5, 1, 14, nan],
                           'd': [False, True, False, False]})
        df1 = df.hasnans
        df2 = dx.DataFrame({'Column Name': list('abcd'),
                            'Has NaN': [False, True, True, False]},
                           columns=['Column Name', 'Has NaN'])
        assert_frame_equal(df1, df2)
