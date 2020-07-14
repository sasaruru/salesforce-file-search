import { LightningElement, track, wire } from 'lwc';
import searchRecords from '@salesforce/apex/CustomSearchController.searchRecords';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class CustomFileSearchForm extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @track searchText;
    // 初期値は取引先
    @track targetObject = 'Account';

    handleSearchTextChange(event){
        this.searchText = event.detail.value;
    }

    handleSearch() {
        let pageRef = this.pageRef;
        searchRecords({searchText : this.searchText, targetObject: this.targetObject})
            .then(result=>{
                fireEvent(pageRef, 'searchResult', result);
                this.error = undefined;
            })
            .catch(error =>{
                this.error = error;
            });
    }

    handleChangeSelect(event){
        this.targetObject = event.detail.value;
    }

    get options(){
        // 対象オブジェクトを追加する場合はここに直接記載
        // TODO soqlで対象オブジェクト取得
        return [
            {'label': '取引先', 'value': 'Account'},
            {'label': 'リード', 'value': 'Lead'},
            {'label': '取引先責任者', 'value': 'Contact'},
        ];
    }
}
