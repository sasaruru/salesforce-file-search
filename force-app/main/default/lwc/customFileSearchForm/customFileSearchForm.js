import { LightningElement, track, wire, api } from 'lwc';
import searchRecords from '@salesforce/apex/CustomSearchController.searchRecords';
import getObjSelectOptions from '@salesforce/apex/CustomSearchController.getObjSelectOptions';
import getObjRecordTypes from '@salesforce/apex/CustomSearchController.getObjRecordTypes';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { fireEvent } from 'c/pubsub';

export default class CustomFileSearchForm extends LightningElement {
    @api targetObjects;
    @api displayLimit;

    @wire(CurrentPageReference) pageRef;
    @track searchText;
    // 初期値は取引先
    @track targetObject;
    @track options;
    @track sortOptions;
    @track sortOptionValue = 'DESC';
    @track recordTypes;
    @track recordTypeValue;

    connectedCallback(){
        this.getOptions();
        this.getSortOptions();
    }
    handleSearchTextChange(event){
        this.searchText = event.detail.value;       
    }

    handleSearch() {
        let pageRef = this.pageRef;
        // 2文字以上ないとエラー
        if(this.searchText.length < 2){
            const evt = new ShowToastEvent({
                title: '検索エラー',
                message: '2文字以上で検索してください',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            return;
        }

        searchRecords({searchText : this.searchText, targetObject: this.targetObject, sortValue: this.sortOptionValue, recordTypeId: this.recordTypeValue, limits: this.displayLimit})
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
        this.recordTypes = null;
        this.getRecordTypes(event.detail.value);

    }

    getRecordTypes(sObjectNmae){
        this.recordTypeValue = 'ALL';
        getObjRecordTypes({sObjectName: sObjectNmae})
        .then(result=>{
            // nullもundifinedも判定対象
            if(result == null || result.length === 0){             
                return;
            }
            console.log(result);
            this.recordTypes = result;
            this.recordTypes.push({label:'全て', value:'ALL'});
            this.recordTypeValue = result[0].value;
        })
        .catch(error =>{
            console.log(error);
            this.error = error;
        });
    }
    handleChangeSort(event){
        this.sortOptionValue = event.detail.value;
    }
    handleChangeRecordType(event){
        this.recordTypeValue = event.detail.value;
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
                // レコードタイプ表示設定
                this.getRecordTypes(result[0].value);
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
