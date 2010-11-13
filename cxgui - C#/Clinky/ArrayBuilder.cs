﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;

namespace Clinky
{
	class ArrayBuilder
	{
        public static T[] Build<T>(ICollection collection)
        {
            if (collection == null)
            {
                return new T[] { };
            }
            List<T> list = new List<T>();
            foreach (object element in collection)
            {
                list.Add((T)element);
            }
            return list.ToArray();
        }
	}
}
