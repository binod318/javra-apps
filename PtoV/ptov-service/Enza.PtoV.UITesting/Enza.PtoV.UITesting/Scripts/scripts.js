function findElementBy(node, match, opt){
	let selectedElem;
	let elems = node.parentNode.querySelectorAll("div:nth-child(2) > ul > li > div:nth-child(1)");		
	for(var i = 0; i < elems.length; i++){
		var li = elems[i];
		let li2;
		if(opt === 1){
			li2 = li.querySelectorAll("div:nth-child(2) > div");
		}
		else if(opt === 2){
			li2 = li.querySelectorAll("div:nth-child(1) > div");
		}
		if (match == li2[0].innerText) {
			console.log(li2[0].innerText);
			selectedElem = li;
			break;
		}	
	}	
	return selectedElem;
}

return findElementBy(arguments[0], arguments[1], arguments[2]);
