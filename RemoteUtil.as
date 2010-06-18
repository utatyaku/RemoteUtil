package libs
{
	import flash.utils.getQualifiedClassName;
	import mx.events.CloseEvent;
	import mx.controls.Alert;
	import mx.rpc.remoting.RemoteObject
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	
	/**
	 * RemoteObjectの通信ユーティリティクラス
	 * 
	 * @version 1.00
	 * @author utatyaku
	 */
	public class RemoteUtil {
		public var debug:Boolean = false; // デバッグフラグ
		public var remote:RemoteObject;
		
		// 各種イベント
		public var resultEvent:Function = null; // 通信成功時のイベント
		public var faultEvent:Function = null; // 通信失敗時のイベント
		public var lastEvent:Function = null; // 通信終了時、一番最後に実行されるイベント
		public var remoteEvent:Function = null; // 実際の通信処理のイベント
		public var beforeErrorAlert:Function = null; // アラートメッセージを表示する前に実行されるイベント
		
		public var removeListner:Boolean = true; // 最後にイベントを削除するか
		
		public var retry:Boolean = false; // リトライフラグ
		public var retryNum:int = 5;
		
		public var showResultErrorMessage:Boolean = true; // 通信結果でnullが返ってきた場合にアラートを表示するか
		public var showFaultMessage:Boolean = true; // 通信失敗時にアラートを表示するか
		public var resultErrorMessage:String = '通信中に問題が発生しました。'; // 通信結果でnullが返ってきた場合のメッセージ
		public var faultMessage:String = '通信エラーが発生しました。\n通信環境を確認してください。'; // 通信エラー時のメッセージ
		
		public var isError:Boolean = false; // エラーの有無
		
		private var retryCount:int = 0;
		
		/**
		 * コンストラクタ
		 * 
		 * @param String destId
		 */
		public function RemoteUtil(destId:String) {
			this.remote = new RemoteObject(destId);
			this.remote.addEventListener(ResultEvent.RESULT, this.complete);
			this.remote.addEventListener(FaultEvent.FAULT, this.complete);
		}
		
		/**
		 * リモート処理の開始
		 * 
		 * @return void
		 */
		public function start():void {
			this.remoteEvent();
		}
		
		/**
		 * 通信が終了した際に実行されるイベント
		 * 
		 * @param Object event
		 * @return void
		 */
		private function complete(event:Object):void {
			var type:String = getQualifiedClassName(event);
			if (type.indexOf('ResultEvent') != -1) {
				// 返ってきた値がnullだった場合の処理
				if (event.result != null && event.result != "") {
					this.isError = true;
					// リトライ
					if (this.retry) {
						this.retryEvent();
						if (this.retryCount < this.retryNum) {
							return;
						}
					}
					// null時のエラーメッセージ
 					if (this.showResultErrorMessage) {
						this.errorAlert(this.resultErrorMessage);
					}
				}
				// 成功時のイベント
				this.resultEvent(ResultEvent(event));
			} else {
				this.isError = true;
				// リトライ
				if (this.retry) {
					this.retryEvent();
					if (this.retryCount < this.retryNum) return;
				}
				// fault時のエラーメッセージ
				if (this.showFaultMessage) {
					this.errorAlert(this.faultMessage);
					if (debug) {
						this.errorAlert(FaultEvent(event).message.toString());
					}
				}
				// fault時のイベント
				if (this.faultEvent != null) {
					this.faultEvent(FaultEvent(event));
				}
			}
			
			if (this.lastEvent != null) {
				this.lastEvent(Object(event));
			}
			
			// イベントの削除
			if (this.removeListner) {
				this.remote.removeEventListener(ResultEvent.RESULT, this.complete);
				this.remote.removeEventListener(FaultEvent.FAULT, this.complete);
			}
			this.remote.disconnect();
		}
		
		/**
		 * リトライ処理
		 * 
		 * @return void
		 */
		private function retryEvent():void {
			this.retryCount++;
			this.remoteEvent();
		}
		
		/**
		 * エラー時のアラート表示
		 * 
		 * @param String message
		 * @return void
		 */
		private function errorAlert(message:String):void {
			if (this.beforeErrorAlert != null) {
				this.beforeErrorAlert();
			}
			Alert.show(message);
		}
		
	}

}