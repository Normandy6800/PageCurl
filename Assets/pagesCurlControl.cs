using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class ReadOnlyAttribute : PropertyAttribute
{

}

[CustomPropertyDrawer(typeof(ReadOnlyAttribute))]
public class ReadOnlyDrawer : PropertyDrawer
{
	public override float GetPropertyHeight(SerializedProperty property,
		GUIContent label)
	{
		return EditorGUI.GetPropertyHeight(property, label, true);
	}

	public override void OnGUI(Rect position,
		SerializedProperty property,
		GUIContent label)
	{
		GUI.enabled = false;
		EditorGUI.PropertyField(position, property, label, true);
		GUI.enabled = true;
	}
}
public class pagesCurlControl : MonoBehaviour {

	public List<Transform> m_pages=new List<Transform>();
	[ReadOnly] [SerializeField] int m_curPageIndexToCurl=0;
	[ReadOnly] [SerializeField] int m_curPageIndexToUnCurl=-1;

	void Start () {
		m_curPageIndexToCurl = 0;
		m_curPageIndexToUnCurl = -1;
		setZoffsetForPages (true);
		check ();
	}
	void check(){
		//should not share material between pages
		for (int i = 0; i < m_pages.Count; i++) {
			Transform page = m_pages [i];
			Material mat= page.GetComponent<MeshRenderer> ().sharedMaterial;
			for (int j = i+1; j < m_pages.Count; j++) {
				Transform _page = m_pages [j];
				Material _mat=_page.GetComponent<MeshRenderer> ().sharedMaterial;
				if (mat == _mat) {
					Debug.LogError ("there are share materials between pages! material:"+mat.name+" and "+_mat.name);
				}
			}
		}
	}
	void setZoffsetForPages(bool curl){
		const float zOffset = 0.0001f;
	    int zOffsetCount = 0;
		if (curl) {
			zOffsetCount = -1;
		}
		for (int i = m_curPageIndexToUnCurl; i >= 0; i--) {
			Transform page = m_pages [i];
			page.GetComponent<MeshRenderer> ().sharedMaterial.SetFloat ("_zOffset",-zOffset*zOffsetCount);
			zOffsetCount++;
		}
		zOffsetCount = 0;
		if (curl == false) {
			zOffsetCount = -1;
		}
		for (int i = m_curPageIndexToCurl; i < m_pages.Count; i++) {
			Transform page = m_pages [i];
			page.GetComponent<MeshRenderer> ().sharedMaterial.SetFloat ("_zOffset",-zOffset*zOffsetCount);
			zOffsetCount++;
		}

	


	}

	public void curl(){
		if (m_curPageIndexToCurl>=m_pages.Count) {
			return;
		
		}

		Transform page = m_pages [m_curPageIndexToCurl];
		page.GetComponent<Animator> ().SetTrigger ("curl");
		m_curPageIndexToUnCurl = m_curPageIndexToCurl;
		m_curPageIndexToCurl++;
		setZoffsetForPages (true);

	}
	public void unCurl(){
		if (m_curPageIndexToUnCurl == -1) {
			return;
		}
	
		Transform page = m_pages [m_curPageIndexToUnCurl];
		page.GetComponent<Animator> ().SetTrigger ("unCurl");
		m_curPageIndexToUnCurl--;
		m_curPageIndexToCurl--;
		setZoffsetForPages (false);

	}
}
