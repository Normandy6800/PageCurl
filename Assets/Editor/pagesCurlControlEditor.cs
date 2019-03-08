
using UnityEditor;

using UnityEngine;
using System.Collections;

// Custom Editor using SerializedProperties.
// Automatic handling of multi-object editing, undo, and prefab overrides.
[CustomEditor(typeof(pagesCurlControl))]
[CanEditMultipleObjects]
public class pagesCurlControlEditor : Editor {
	

	void OnEnable () {

	}

	public override void OnInspectorGUI() {

		DrawDefaultInspector ();
		//serializedObject.Update ();

		//serializedObject.ApplyModifiedProperties ();

		if (GUILayout.Button ("curl")) {
			((pagesCurlControl)target).curl ();
		}
		if (GUILayout.Button ("unCurl")) {
			((pagesCurlControl)target).unCurl ();
		}
	}



}