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
    });
    document.getElementById('add_ench_button').addEventListener("click", function() {
        let type = document.getElementById('add_enchantment_type').value;
        let level = document.getElementById('add_enchant_level').value;
        listEnchant(type, level);
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
    });
}
