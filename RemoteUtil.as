package libs
{
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import mx.events.CloseEvent;
	import mx.rpc.remoting.RemoteObject
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	import mx.controls.Alert;
	import libs.Check;
	
	/**
	 * RemoteObjectの通信ユーティリティクラス
	 * 
	 * @author feb0223
	 */
	public class RemoteUtil {
		private var debug:Boolean = false;
		
		public var remote:RemoteObject;
		
		public var resultEvent:Function = null; // 通信成功時のイベント
		public var faultEvent:Function = null; // 通信失敗時のイベント
		public var lastEvent:Function = null; // 通信終了時、一番最後に実行されるイベント
		public var remoteEvent:Function = null; // 実際の通信処理のイベント
		
		public var removeListner:Boolean = true;// 最後にイベントを削除するか
		
		public var retry:Boolean = false; // リトライフラグ
		public var retryNum:int = 5;
		
		public var showResultErrorMessage:Boolean = true; // 通信結果でnullが返ってきた場合にアラートを表示するか
		public var showFaultMessage:Boolean = true; // 通信失敗時にアラートを表示するか
		public var resultErrorMessage:String = '通信中に問題が発生しました。'; // 通信結果でnullが返ってきた場合のメッセージ
		public var faultMessage:String = '通信エラーが発生しました。\n通信環境を確認してください。'; // 通信エラー時のメッセージ
		
		public var isError:Boolean = false; // エラーの有無
		public var reconnection:Boolean = false; // 再接続フラグ
		
		private var autoSaveTmer:Timer = null;
		private var retryCount:int = 0;
		
		/**
		 * コンストラクタ
		 * 
		 * @param String destId
		 * @param Timer autoSaveTmer
		 */
		public function RemoteUtil(destId:String, autoSaveTmer:Timer = null) {
			this.remote = new RemoteObject(destId);
			remote.addEventListener(ResultEvent.RESULT, this.complete);
			remote.addEventListener(FaultEvent.FAULT, this.complete);
			if (autoSaveTmer != null) {
				this.autoSaveTmer = autoSaveTmer;
			}
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
				if (Check.empty(event.result)) {
					this.isError = true;
					// リトライ
					if (this.retry) {
						this.retryEvent();
						if (this.retryCount < this.retryNum) return;
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
			if (this.autoSaveTmer != null) {
				// 自動保存を停止する
				this.autoSaveTmer.stop();
			}
			
			/*
			if (this.reconnection) {
				Alert.buttonWidth = 80;
				Alert.noLabel = '再接続';
				Alert.show(message, '', Alert.OK | Alert.NO, null,
					function (event:CloseEvent):void {
						if (autoSaveTmer != null) {
							autoSaveTmer.start();
						}
						if (event.detail == Alert.NO) {
							if (initRemoteEvent != null) {
								initRemoteEvent();
							}
							remote.addEventListener(ResultEvent.RESULT,complete);
							remote.addEventListener(FaultEvent.FAULT, complete);
							retryCount = 0;
							remoteEvent();
						}
					}
				);
				return;
			}
			*/
			Alert.show(message, '', 0x4, null,
				function ():void {
					if (autoSaveTmer != null) {
						autoSaveTmer.start();
					}
				}
			);
		}
		
	}

}