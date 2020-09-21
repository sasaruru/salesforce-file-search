import { LightningElement, track, wire, api } from 'lwc';
import searchRecords from '@salesforce/apex/CustomSearchController.searchRecords';
import getObjSelectOptions from '@salesforce/apex/CustomSearchController.getObjSelectOptions';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class CustomFileSearchForm extends LightningElement {
    @api targetObjects;
    
    @wire(CurrentPageReference) pageRef;
    @track searchText;
    // 初期値は取引先
    @track targetObject;
    @track options;
    @track sortOptions;
    @track sortOptionValue = 'DESC';

    connectedCallback(){
        this.getOptions();
        this.getSortOptions();
    }
    handleSearchTextChange(event){
        this.searchText = event.detail.value;       
    }

    handleSearch() {
        let pageRef = this.pageRef;
        searchRecords({searchText : this.searchText, targetObject: this.targetObject, sortValue: this.sortOptionValue})
            .then(result=>{
                const params = {targetObject: this.targetObject, result: result};
                fireEvent(pageRef, 'searchResult', params);
                this.error = undefined;
            })
            .catch(error =>{
                this.error = error;
            });
    }

    handleChangeSelect(event){
        this.targetObject = event.detail.value;
    }

    getOptions(){
        // undifinedも含む
        if(this.targetObjects == null){
            return [];
        }
        const objList = this.targetObjects.split(',');
        getObjSelectOptions({objs: objList})
            .then(result=>{
                console.log(result);
                this.targetObject = result[0].value;
                this.options = result;
            })
            .catch(error =>{
                console.log(error);
                this.error = error;
            });
    }
    getSortOptions() {
        this.sortOptions =  [
            { label: '降順', value: 'DESC' },
            { label: '昇順', value: 'ASC' },
        ];
    }
}
