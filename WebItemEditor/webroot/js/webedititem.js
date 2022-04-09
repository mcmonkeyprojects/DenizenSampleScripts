enchantsKnown = {};

function loaditemdata() {
    fetch("/web_edit_item.json" + window.location.search, { method: 'POST' }).then(res => res.json()).then(obj => {
        document.getElementById('material_name').textContent = obj.material;
        document.getElementById('display_name').textContent = obj.display;
        document.getElementById('lore').textContent = obj.lore;
        for (var key in obj.enchantments) {
            listEnchant(key, obj.enchantments[key]);
        }
        let enchantmentDropdown = document.getElementById('add_enchantment_type');
        for (var enchant_type in obj.available_ench_types) {
            enchantmentDropdown.insertAdjacentHTML("beforeend", "<option>" + obj.available_ench_types[enchant_type] + "</option>");
        }
        document.getElementById('hide_data').checked = obj.hides == "true";
        renderPreview();
    });
    document.getElementById('add_ench_button').addEventListener("click", function() {
        let type = document.getElementById('add_enchantment_type').value;
        let level = document.getElementById('add_enchant_level').value;
        listEnchant(type, level);
        renderPreview();
    });
    document.getElementById('hide_data').addEventListener("click", function() {
        renderPreview();
    });
    document.getElementById('sendback_button').addEventListener("click", function() {
        let object = {
            hides: document.getElementById('hide_data').checked ? "true" : "false",
            display: document.getElementById('display_name').value,
            lore: document.getElementById('lore').value,
            enchantments: enchantsKnown
        };
        console.log(JSON.stringify(object));
        fetch("/web_edit_item_upload" + window.location.search, { method: 'POST', body: JSON.stringify(object) });
    });
}

function listEnchant(enchant, level) {
    let existing = document.getElementById("ench_list_" + enchant);
    if (existing) {
        existing.remove();
    }
    enchantsKnown[enchant] = level;
    document.getElementById('existing_enchants').insertAdjacentHTML("beforeend", '<li class="list-group-item" id="ench_list_' + enchant + '"><center>'
    + enchant + ' &nbsp; ' + level + ' &nbsp; <button type="button" class="btn btn-danger" id="remove_ench_' + enchant + '">Remove</button></center></li>');
    document.getElementById("remove_ench_" + enchant).addEventListener("click", function() {
        document.getElementById("ench_list_" + enchant).remove();
        delete enchantsKnown[enchant];
        renderPreview();
    });
}

function appendText(previewObj, text) {
    let color = "#ffffff";
    let bold = false, italic = false, underline = false, strike = false;
    function resetFormat() {
        bold = false; strike = false; underline = false; italic = false;
    }
    for (var i = 0; i < text.length; i++) {
        let char = text.charAt(i);
        if (char == "\n") {
            previewObj.appendChild(document.createElement('br'));
        }
        else if (char == '&' && i + 1 < text.length) {
            i++;
            switch (text.charAt(i)) {
                case '0': color = "#000000"; resetFormat(); break;
                case '1': color = "#0000AA"; resetFormat(); break;
                case '2': color = "#00AA00"; resetFormat(); break;
                case '3': color = "#00AAAA"; resetFormat(); break;
                case '4': color = "#AA0000"; resetFormat(); break;
                case '5': color = "#AA00AA"; resetFormat(); break;
                case '6': color = "#FFAA00"; resetFormat(); break;
                case '7': color = "#AAAAAA"; resetFormat(); break;
                case '8': color = "#555555"; resetFormat(); break;
                case '9': color = "#5555FF"; resetFormat(); break;
                case 'a': case 'A': color = "#55FF55"; resetFormat(); break;
                case 'b': case 'B': color = "#55FFFF"; resetFormat(); break;
                case 'c': case 'C': color = "#FF5555"; resetFormat(); break;
                case 'd': case 'D': color = "#FF55FF"; resetFormat(); break;
                case 'e': case 'E': color = "#FFFF55"; resetFormat(); break;
                case 'f': case 'F': color = "#ffffff"; resetFormat(); break;
                case 'r': case 'R': color = "#ffffff"; resetFormat(); break;
                case 'k': case 'K': break;
                case 'l': case 'L': bold = true; break;
                case 'm': case 'M': strike = true; break;
                case 'n': case 'N': underline = true; break;
                case 'o': case 'O': italic = true; break;
                case '#': if (i + 7 < text.length) { color = text.substring(i, i + 7); i += 6; resetFormat(); } break;
            }
        }
        else {
            let newSpan = document.createElement('span');
            newSpan.style.color = color;
            newSpan.style.fontWeight = bold ? "bold" : "normal";
            newSpan.style.fontStyle = italic ? "italic" : "normal";
            newSpan.style.textDecoration = strike ? (underline ? "underline line-through" : "line-through") : (underline ? "underline" : "none");
            newSpan.textContent = char;
            previewObj.appendChild(newSpan);
        }
    }
}

function renderPreview() {
    let previewObj = document.getElementById('item_preview');
    while (previewObj.firstChild) {
        previewObj.removeChild(previewObj.firstChild);
    }
    let hideExtras = document.getElementById('hide_data').checked;
    let display = document.getElementById('display_name').value;
    let lore = document.getElementById('lore').value;
    appendText(previewObj, display + "\n");
    if (!hideExtras) {
        for (var enchant_type in enchantsKnown) {
            appendText(previewObj, "&7" + enchant_type + " " + enchantsKnown[enchant_type] + "\n");
        }
    }
    appendText(previewObj, lore);
}
