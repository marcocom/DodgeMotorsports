
/**
 * 
 * MORFsite - Flash Framework 
 * by David Barlia (c) 2009
 *
 * You may distribute this class freely, provided it is not modified in any way (including
 * removing this header or changing the package path).
 *
 * Please contact <david@barliesque.com> prior to distributing modified versions of this class.
 * 
 * Pertaining to all classes in the package com.barliesque.morf and sub-packages thereof,
 * permission is hereby granted, free of charge, to any person obtaining a copy of this
 * code library ("THE LIBRARY") and associated documentation files to use, copy, distribute
 * the library.  No restriction is applicable to compiled products making use of the library.
 * 
 * THE LIBRARY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE LIBRARY OR THE USE OR OTHER DEALINGS IN THE LIBRARY.
 * 
 */

package com.barliesque.utils {
	
	/**
	* ...
	* @author David Barlia
	* An occasionally useful function, because E4X requires
	* that any property in a query like:  .(@name == "fred")
	* must exist in all nodes of the XMLList being queried.
	* If the name attribute were missing from the above
	* query, a runtime error would result.  This function
	* gets around that.
	*/
	
	public function findXML(list:XMLList, condition:Function):XMLList {
		var found:XMLList = new XMLList();
		var nodeCount:int = list.length();
		for (var i:int = 0; i < nodeCount; i++) {
			if (condition(list[i])) found += list[i];
		}
		return found;
	}
	
}