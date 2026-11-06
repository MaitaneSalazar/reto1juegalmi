import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, map, tap, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { NuevoUsuario, Usuario } from '../models/usuario.model';

// Lo que se guarda tras iniciar sesión
export interface Sesion {
  token: string;                 // JWT que devuelve la API (dura 7 días)
  usuario: Usuario;
}

const CLAVE = 'juegalmi_sesion';       // clave en localStorage
const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class SesionService {
  private http = inject(HttpClient);
  private sesion = signal<Sesion | null>(this.leer());

  readonly usuario = computed(() => this.sesion()?.usuario ?? null);
  readonly token = computed(() => this.sesion()?.token ?? null);
  readonly logueado = computed(() => this.sesion() !== null);

  // "Ane Etxeberria" (la API ya lo trae; si no, se compone)
  readonly nombreCompleto = computed(() => {
    const u = this.usuario();
    return u ? (u.nombre_completo ?? `${u.nombre} ${u.apellido1}`) : '';
  });

  // "AE"
  readonly iniciales = computed(() => {
    const u = this.usuario();
    return u ? (u.iniciales ?? (u.nombre[0] + u.apellido1[0]).toUpperCase()) : '';
  });

  // ---------------------------------------------------------- LOGIN · POST /api/login
  login(email: string, password: string): Observable<Usuario> {
    return this.http.post<Sesion>(`${API}/login`, { email, password }).pipe(
      tap(s => {
        // La app es para clientes: los trabajadores usan la web
        if (s.usuario.tipo !== 'cliente') throw new Error('Esta app es para clientes. Los trabajadores usáis la web de JuegAlmi.');
        this.guardar(s);
      }),
      map(s => s.usuario),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // ---------------------------------------------------------- REGISTRO · POST /api/registro (201 + sesión iniciada)
  registrar(datos: NuevoUsuario): Observable<Usuario> {
    return this.http.post<Sesion>(`${API}/registro`, datos).pipe(
      tap(s => this.guardar(s)),
      map(s => s.usuario),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // ---------------------------------------------------------- MIS DATOS · GET /api/yo (incluye contadores)
  refrescar(): Observable<Usuario> {
    return this.http.get<Usuario>(`${API}/yo`).pipe(tap(u => this.actualizarLocal(u)));
  }

  // ---------------------------------------------------------- MODIFICAR · PUT /api/yo (solo lo que cambia)
  actualizarDatos(cambios: Record<string, string | null>): Observable<Usuario> {
    return this.http.put<Usuario>(`${API}/yo`, cambios).pipe(
      tap(u => this.actualizarLocal(u)),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // POST /api/yo/foto (multipart, campo "imagen"): devuelve el usuario con foto_perfil_url
  subirFoto(imagen: Blob, nombre: string): Observable<Usuario> {
    const datos = new FormData();
    datos.append('imagen', imagen, nombre);
    return this.http.post<Usuario>(`${API}/yo/foto`, datos).pipe(tap(u => this.actualizarLocal(u)));
  }

  // ---------------------------------------------------------- CERRAR SESIÓN
  cerrar(): void {
    this.sesion.set(null);
    try { localStorage.removeItem(CLAVE); } catch { /* sin almacenamiento */ }
  }

  // Mensaje para el usuario a partir del error de la API: { error, codigo, mensaje, campos }
  mensaje(e: unknown): string {
    if (e instanceof HttpErrorResponse) {
      if (e.status === 0) return 'No se puede conectar con el servidor. ¿Estás en la misma wifi que la API?';
      if (e.status >= 500) return 'Error del servidor. Inténtalo más tarde.';
      const campos = e.error?.campos as Record<string, string> | undefined;
      if (campos && Object.keys(campos).length) return Object.values(campos)[0];
      return e.error?.mensaje ?? 'Ha ocurrido un error. Inténtalo de nuevo.';
    }
    return e instanceof Error ? e.message : 'Ha ocurrido un error.';
  }

  // ---------------------------------------------------------- AUXILIARES
  private actualizarLocal(u: Usuario): void {
    const s = this.sesion();
    if (s) this.guardar({ ...s, usuario: { ...s.usuario, ...u } });
  }

  private guardar(s: Sesion): void {
    this.sesion.set(s);
    try { localStorage.setItem(CLAVE, JSON.stringify(s)); } catch { /* sin almacenamiento */ }
  }

  private leer(): Sesion | null {
    try { return JSON.parse(localStorage.getItem(CLAVE) ?? 'null'); } catch { return null; }
  }
}
